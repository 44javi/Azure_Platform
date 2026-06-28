#!/usr/bin/env bash

set -uo pipefail

TTL_DAYS="${TTL_DAYS:-10}"
TTL_HOURS="${TTL_HOURS:-1}"
DRY_RUN="$(echo "${DRY_RUN:-false}" | tr '[:upper:]' '[:lower:]')"

CREATED_TAG="${CREATED_TAG:-CreatedOnDate}"

PROTECTED_RG_REGEX="${PROTECTED_RG_REGEX:-AzureBackupRG_.*|cloud-shell-storage-.*}"
MAX_PASSES="${MAX_PASSES:-5}"
PASS_WAIT_SECONDS="${PASS_WAIT_SECONDS:-60}"
PARALLELISM="${PARALLELISM:-8}"
FAIL_ON_LEFTOVERS="$(echo "${FAIL_ON_LEFTOVERS:-true}" | tr '[:upper:]' '[:lower:]')"
TREAT_NULL_CREATED_AS_EXPIRED="$(echo "${TREAT_NULL_CREATED_AS_EXPIRED:-false}" | tr '[:upper:]' '[:lower:]')"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

log()  { printf '%s | %s\n' "$(date -u +%H:%M:%S)" "$*"; }
die()  { log "ERROR: $*"; exit 1; }

command -v az >/dev/null || die "az CLI not found"
command -v jq >/dev/null || die "jq not found"

# ---------------------------------------------------------------- cutoff ----
if [[ -n "$TTL_HOURS" ]]; then AGE_SPEC="${TTL_HOURS} hours"; else AGE_SPEC="${TTL_DAYS} days"; fi

cutoff_ts() {
  date -u -d "$1 ago" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null && return
  python3 - "$1" <<'PY'
import sys, datetime
n, unit = sys.argv[1].split()
delta = datetime.timedelta(**{unit: float(n)})
print((datetime.datetime.now(datetime.timezone.utc) - delta).strftime('%Y-%m-%dT%H:%M:%SZ'))
PY
}
CUTOFF="$(cutoff_ts "$AGE_SPEC")" || die "could not compute cutoff timestamp"

# ---------------- subscription guard --
if [[ -z "${SUBSCRIPTION_ID:-}" ]]; then
  SUBSCRIPTION_ID="$(az account show --query id -o tsv)" || die "no az login context"
fi
az account set --subscription "$SUBSCRIPTION_ID" || die "cannot select subscription $SUBSCRIPTION_ID"
SUB_NAME="$(az account show --query name -o tsv)"

log "subscription : $SUB_NAME ($SUBSCRIPTION_ID)"
log "TTL          : $AGE_SPEC (cutoff $CUTOFF, resources created before this are destroyed)"
log "RG aging tag : $CREATED_TAG (RGs stamped before $CUTOFF are deleted)"
log "dry run      : $DRY_RUN"

# ------------------------------------------------------- protected RG set ---
az group list -o json > "$WORKDIR/groups.json" || die "cannot list resource groups"
{
  jq -r '.[] | select(.managedBy != null) | .name' "$WORKDIR/groups.json"
  jq -r '.[].name' "$WORKDIR/groups.json" | grep -Ei "^(${PROTECTED_RG_REGEX})$" || true
} | tr '[:upper:]' '[:lower:]' | sort -u > "$WORKDIR/protected_rgs.txt"
PROTECTED_JSON="$(jq -R . "$WORKDIR/protected_rgs.txt" | jq -s .)"
log "protected RGs: $(paste -sd ', ' "$WORKDIR/protected_rgs.txt" | sed 's/^$/(none)/')"

EXPIRED_RG_JSON="[]"

# -------------- resource query ---
# ARM list with $expand=createdTime is the only uniform, GA source of
# resource creation time. Handles pagination via nextLink.
fetch_expired() {
  local url="https://management.azure.com/subscriptions/${SUBSCRIPTION_ID}/resources?api-version=2021-04-01&\$expand=createdTime"
  local n=0
  rm -f "$WORKDIR"/page_*.json
  while [[ -n "$url" ]]; do
    az rest --method get --url "$url" -o json > "$WORKDIR/page_$n.json" || return 1
    url="$(jq -r '.nextLink // empty' "$WORKDIR/page_$n.json")"
    n=$((n + 1))
  done
  jq -s --arg cutoff "$CUTOFF" \
        --argjson protected "$PROTECTED_JSON" --argjson expiredRg "$EXPIRED_RG_JSON" \
        --arg nullExpired "$TREAT_NULL_CREATED_AS_EXPIRED" '
    [ .[].value[]
      | select( (.createdTime != null and .createdTime < $cutoff)
                or (.createdTime == null and $nullExpired == "true") )
      | . + { rgName: ((.id | capture("/resourceGroups/(?<rg>[^/]+)/"; "i") | .rg | ascii_downcase)? // "") }
      | .rgName as $rg
      | select($rg != "" and (($protected | index($rg)) == null) and (($expiredRg | index($rg)) == null))
    ]' "$WORKDIR"/page_*.json
}

# Resources ARM reports with a null createdTime are invisible to the age filter.
# Reuses the page_*.json already fetched by fetch_expired
# Applies the same protected-RG exclusion so the report matches what would
# actually be deleted if TREAT_NULL_CREATED_AS_EXPIRED were enabled.
fetch_unknown_age() {
  jq -s --argjson protected "$PROTECTED_JSON" '
    [ .[].value[]
      | select(.createdTime == null)
      | . + { rgName: ((.id | capture("/resourceGroups/(?<rg>[^/]+)/"; "i") | .rg | ascii_downcase)? // "") }
      | .rgName as $rg | select($rg != "" and (($protected | index($rg)) == null))
    ]' "$WORKDIR"/page_*.json
}

# Never silently ignore resources with no createdTime: either report them as skipped, or note they are being treated as expired.
report_unknown_age() {
  fetch_unknown_age > "$WORKDIR/unknown_age.json" 2>/dev/null || return 0
  local n
  n="$(jq 'length' "$WORKDIR/unknown_age.json" 2>/dev/null || echo 0)"
  [[ "$n" -eq 0 ]] && return 0
  if [[ "$TREAT_NULL_CREATED_AS_EXPIRED" == "true" ]]; then
    log "$n resource(s) have no ARM createdTime; treating as expired (TREAT_NULL_CREATED_AS_EXPIRED=true)"
  else
    log "$n resource(s) have no ARM createdTime and are being SKIPPED:"
    print_expired "$WORKDIR/unknown_age.json"
    log "set TREAT_NULL_CREATED_AS_EXPIRED=true to delete them"
  fi
}

# Coarse delete order. 0 = workloads that hold dependencies, 3 = base networking.
RANK_FILTER='
  def rank:
    (.type | ascii_downcase) as $t
    | if   $t == "microsoft.network/virtualnetworks"
        or $t == "microsoft.network/networksecuritygroups"
        or $t == "microsoft.network/routetables"
        or $t == "microsoft.network/privatednszones"            then 3
      elif ($t | startswith("microsoft.network/"))
        or $t == "microsoft.compute/disks"                      then 2
      elif $t == "microsoft.compute/virtualmachines"
        or $t == "microsoft.compute/virtualmachinescalesets"
        or $t == "microsoft.containerservice/managedclusters"
        or $t == "microsoft.databricks/workspaces"
        or $t == "microsoft.machinelearningservices/workspaces"
        or $t == "microsoft.cognitiveservices/accounts"
        or $t == "microsoft.apimanagement/service"
        or $t == "microsoft.web/sites"
        or $t == "microsoft.app/containerapps"                  then 0
      else 1 end;'

print_expired() {
  if command -v column >/dev/null; then
    jq -r '.[] | [.createdTime, .rgName, .type, .name] | @tsv' "$1" \
      | sort | column -t -s $'\t' | sed 's/^/    /'
  else
    jq -r '.[] | [.createdTime, .rgName, .type, .name] | @tsv' "$1" \
      | sort | sed 's/^/    /'
  fi
}

# --------- type-specific pre-deletes --
# Log Analytics: a plain ARM delete soft-deletes for 14 days and there is no
# purge command, so force-delete here instead of the generic pass.
predelete_log_analytics() {
  jq -r '.[] | select((.type | ascii_downcase) == "microsoft.operationalinsights/workspaces")
             | [.rgName, .name] | @tsv' "$1" |
  while IFS=$'\t' read -r rg name; do
    log "  force-deleting Log Analytics workspace: $rg/$name"
    az monitor log-analytics workspace delete -g "$rg" -n "$name" --force true --yes --only-show-errors \
      || log "  failed (retried as soft delete in generic pass): $rg/$name"
  done
}

# Recovery Services: vault delete fails while backup items exist. Best effort:
# disable soft delete, then drop protection and data for every item.
predelete_recovery_vaults() {
  jq -r '.[] | select((.type | ascii_downcase) == "microsoft.recoveryservices/vaults")
             | [.rgName, .name] | @tsv' "$1" |
  while IFS=$'\t' read -r rg name; do
    log "  draining Recovery Services vault: $rg/$name"
    az backup vault backup-properties set -g "$rg" -n "$name" \
      --soft-delete-feature-state Disable --only-show-errors >/dev/null 2>&1 || true
    az backup item list -g "$rg" -v "$name" -o json 2>/dev/null | jq -c '.[]' |
    while IFS= read -r item; do
      az backup protection disable --yes --delete-backup-data true --only-show-errors \
        -g "$rg" -v "$name" \
        --container-name "$(jq -r '.properties.containerName' <<<"$item")" \
        --item-name "$(jq -r '.properties.friendlyName' <<<"$item")" \
        --backup-management-type "$(jq -r '.properties.backupManagementType' <<<"$item")" \
        >/dev/null 2>&1 || true
    done
  done
}

# --------------------soft purge --
purge_soft_deleted() {
  log "purging soft-deleted services"

  az keyvault list-deleted --resource-type vault -o json 2>/dev/null | jq -c '.[]' |
  while IFS= read -r kv; do
    local_name="$(jq -r '.name' <<<"$kv")"
    local_loc="$(jq -r '.properties.location' <<<"$kv")"
    if [[ "$(jq -r '.properties.purgeProtectionEnabled // false' <<<"$kv")" == "true" ]]; then
      log "  SKIP key vault '$local_name': purge protection enabled, must age out on its own"
      continue
    fi
    log "  purging key vault: $local_name ($local_loc)"
    az keyvault purge --name "$local_name" --location "$local_loc" --no-wait --only-show-errors || true
  done

  # Cognitive Services covers AI Foundry accounts (kind AIServices); projects are child resources and disappear with the account.
  az cognitiveservices account list-deleted -o json 2>/dev/null |
    jq -r '.[].id | capture("/locations/(?<l>[^/]+)/resourceGroups/(?<g>[^/]+)/deletedAccounts/(?<n>[^/]+)"; "i") | [.l, .g, .n] | @tsv' |
  while IFS=$'\t' read -r loc rg name; do
    log "  purging cognitive services / foundry account: $rg/$name ($loc)"
    az cognitiveservices account purge -l "$loc" -g "$rg" -n "$name" --only-show-errors || true
  done

  az apim deletedservice list -o json 2>/dev/null | jq -r '.[] | [.location, .serviceId] | @tsv' |
  while IFS=$'\t' read -r loc svc_id; do
    name="${svc_id##*/}"
    log "  purging API Management: $name ($loc)"
    az apim deletedservice purge --service-name "$name" --location "$loc" --only-show-errors || true
  done

  az appconfig list-deleted -o json 2>/dev/null | jq -r '.[].name' |
  while IFS= read -r name; do
    log "  purging App Configuration: $name"
    az appconfig purge --name "$name" --yes --only-show-errors || true
  done
}

# ---------- expired resource groups --
fetch_expired_rgs() {
  jq -r --arg cutoff "$CUTOFF" --arg createdTag "$CREATED_TAG" '
    [ .[]
      | (((.tags // {})[$createdTag]) // "") as $created
      | select($created != "" and $created < $cutoff)
      | {name: .name, created: $created} ]
    | sort_by(.created)
    | .[] | [.name, .created] | @tsv' "$WORKDIR/groups.json" |
  while IFS=$'\t' read -r name created; do
    grep -Fxiq "$name" "$WORKDIR/protected_rgs.txt" && continue
    printf '%s\t%s\n' "$name" "$created"
  done
}

# RGs that carry the ${CREATED_TAG} tag but are still younger than the cutoff:
# they are left in place this run and will be deleted on a future run once their tag ages past the TTL.
fetch_kept_rgs() {
  jq -r --arg cutoff "$CUTOFF" --arg createdTag "$CREATED_TAG" '
    .[]
    | (((.tags // {})[$createdTag]) // "") as $created
    | select($created != "" and $created >= $cutoff)
    | .name' "$WORKDIR/groups.json" |
  while IFS= read -r name; do
    grep -Fxiq "$name" "$WORKDIR/protected_rgs.txt" && continue
    printf '%s\n' "$name"
  done
}

report_kept_rgs() {
  local kept
  kept="$(fetch_kept_rgs | paste -sd ', ')"
  [[ -z "$kept" ]] && return 0
  log "kept (not yet at TTL): $kept"
}

delete_expired_rgs() {
  fetch_expired_rgs > "$WORKDIR/expired_rgs.txt"
  local n
  n="$(wc -l < "$WORKDIR/expired_rgs.txt" | tr -d ' ')"
  if [[ "$n" -eq 0 ]]; then
    log "no resource groups expired by ${CREATED_TAG} tag"
    return 0
  fi
  if [[ "$DRY_RUN" == "true" ]]; then
    log "DRY RUN: these $n resource group(s) and EVERYTHING inside them would be"
    log "         deleted (created before cutoff $CUTOFF; set DRY_RUN=false to delete):"
  else
    log "deleting these $n resource group(s) and everything inside them"
    log "         (created before cutoff $CUTOFF):"
  fi
  # expired_rgs.txt is "name<TAB>created", oldest first.
  {
    printf 'RESOURCE_GROUP\t%s\n' "$CREATED_TAG"
    cat "$WORKDIR/expired_rgs.txt"
  } | { command -v column >/dev/null && column -t -s $'\t' || cat; } | sed 's/^/    /'
  if [[ "$DRY_RUN" == "true" ]]; then
    # Hide these doomed RGs' contents from the per-resource report below so the
    # same resources are not listed twice. A real run deletes the RGs first,
    # then the per-resource passes retry anything that survived.
    EXPIRED_RG_JSON="$(cut -f1 "$WORKDIR/expired_rgs.txt" | tr '[:upper:]' '[:lower:]' | jq -R . | jq -s .)"
    return 0
  fi
  cut -f1 "$WORKDIR/expired_rgs.txt" |
    xargs -r -P "$PARALLELISM" -I{} bash -c '
      if az group delete -n "$1" --yes --only-show-errors >/dev/null 2>&1; then
        echo "    deleted RG: $1"
      else
        echo "    failed to delete RG (contents retried per-resource): $1"
      fi' _ {}
}

# ==================================================================== main ===
# Resource groups expired by the policy-stamped CreatedOnDate tag are removed
# First; the per-resource passes below then age out anything left in the
# surviving RGs by ARM createdTime.
delete_expired_rgs
report_kept_rgs

pass=1
while (( pass <= MAX_PASSES )); do
  fetch_expired > "$WORKDIR/expired.json" || die "failed to list resources"
  total="$(jq 'length' "$WORKDIR/expired.json")"

  (( pass == 1 )) && report_unknown_age

  if [[ "$total" -eq 0 ]]; then
    log "pass $pass: no expired resources remain"
    break
  fi

  log "pass $pass/$MAX_PASSES: $total expired resource(s)"
  print_expired "$WORKDIR/expired.json"

  if [[ "$DRY_RUN" == "true" ]]; then
    log "dry run: nothing deleted"
    break
  fi

  if (( pass == 1 )); then
    predelete_log_analytics "$WORKDIR/expired.json"
    predelete_recovery_vaults "$WORKDIR/expired.json"
  fi

  for r in 0 1 2 3; do
    jq -r "$RANK_FILTER"' .[] | select(rank == '"$r"') | .id' "$WORKDIR/expired.json" |
      xargs -r -P "$PARALLELISM" -I{} bash -c '
        if az resource delete --ids "$1" --only-show-errors >/dev/null 2>&1; then
          echo "    deleted: $1"
        else
          echo "    failed (will retry next pass): $1"
        fi' _ {}
  done

  pass=$((pass + 1))
  if (( pass <= MAX_PASSES )); then
    log "waiting ${PASS_WAIT_SECONDS}s for deletions to settle"
    sleep "$PASS_WAIT_SECONDS"
  fi
done

if [[ "$DRY_RUN" != "true" ]]; then
  purge_soft_deleted
fi

# ------------------- summary --
fetch_expired > "$WORKDIR/leftover.json" || die "failed to list resources for summary"
leftover="$(jq 'length' "$WORKDIR/leftover.json")"

if [[ "$DRY_RUN" == "true" ]]; then
  rg_count="$(wc -l < "$WORKDIR/expired_rgs.txt" 2>/dev/null | tr -d ' ')"
  rg_count="${rg_count:-0}"
  log "dry run complete: $rg_count whole resource group(s) and $leftover additional standalone resource(s) would be destroyed"
  exit 0
fi

if [[ "$leftover" -gt 0 ]]; then
  log "WARNING: $leftover expired resource(s) survived all passes:"
  print_expired "$WORKDIR/leftover.json"
  [[ "$FAIL_ON_LEFTOVERS" == "true" ]] && exit 1
else
  log "cleanup complete: no expired resources remain"
fi
exit 0

