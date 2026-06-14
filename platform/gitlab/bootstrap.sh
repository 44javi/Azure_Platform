#!/usr/bin/env bash
# =============================================================================
# One-time bootstrap for the GitLab org-structure root module.
#
# Creates the Azure identity the CI pipeline uses to reach the Terraform state
# backend, with NO stored Azure secret (workload identity federation / OIDC).
# Run this ONCE per tenant, by hand, before the pipeline can run. It is not part
# of `terraform apply` because Terraform needs this identity to exist first
# (the classic bootstrap chicken-and-egg).
#
# What it does:
#   1. Creates an Entra ID app registration + service principal (the "state SP").
#   2. Adds a federated credential trusting GitLab's OIDC token for `main`.
#   3. (optional) Adds a second federated credential for merge request pipelines.
#   4. Grants the SP Storage Blob Data Contributor on the state storage account.
#   5. Prints the values you paste into GitLab CI/CD variables.
#
# What it does NOT do (must be done in the GitLab UI, see "GitLab side" at end):
#   - Create the first GITLAB_TOKEN group access token.
#   - Set the CI/CD variables.
#   - Configure SAML SSO and the IdP groups claim.
#
# Prereqs: az CLI, an `az login` as someone who can create app registrations and
# assign roles on the state storage account. Read-only otherwise; the only writes
# are the SP, its federated credential(s), and one role assignment.
# =============================================================================
set -euo pipefail

# --- Fill these in (or export them before running) ---------------------------
: "${COMPANY_ABBR:?Set COMPANY_ABBR to the organization prefix, lowercased}"
# Identity belongs to the GitLab project's CI pipeline. It only needs state
# access today
APP_NAME="${APP_NAME:-sp-${COMPANY_ABBR}-gitlab-cicd-global}"

# GitLab project that runs the pipeline, as group/subgroup/project path.
: "${GITLAB_PROJECT_PATH:?Set GITLAB_PROJECT_PATH to group/subgroup/project}"
GITLAB_ISSUER="${GITLAB_ISSUER:-https://gitlab.com}"      # self-managed: your instance URL

# State backend (must match .gitlab-ci.yml / .debug.global.sh).
: "${BACKEND_SUBSCRIPTION_ID:?Set BACKEND_SUBSCRIPTION_ID to the state subscription id}"
: "${BACKEND_RESOURCE_GROUP:?Set BACKEND_RESOURCE_GROUP to the state resource group}"
: "${BACKEND_STORAGE_ACCOUNT:?Set BACKEND_STORAGE_ACCOUNT to the state storage account}"

# Set to "true" to also trust merge request pipelines (so `plan` on MRs can read
# state). Leave "false" if you make MR pipelines validate-only (recommended).
ADD_MR_CREDENTIAL="${ADD_MR_CREDENTIAL:-false}"
# -----------------------------------------------------------------------------

TENANT_ID="$(az account show --query tenantId -o tsv)"

echo "==> Creating app registration: ${APP_NAME}"
APP_ID="$(az ad app list --display-name "$APP_NAME" --query '[0].appId' -o tsv)"
if [ -z "$APP_ID" ]; then
  APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)"
  echo "    created appId=${APP_ID}"
else
  echo "    already exists, reusing appId=${APP_ID}"
fi

# Service principal for the app (needed for the role assignment).
# A freshly created app registration can take a few seconds to replicate across
# Microsoft Graph. If `az ad sp create` races that replication it hits a replica
# that returns an empty body and fails with a JSON decode error. Retry with
# backoff to absorb the lag.
if ! az ad sp show --id "$APP_ID" >/dev/null 2>&1; then
  for attempt in 1 2 3 4 5 6; do
    if [ "$attempt" -eq 6 ]; then
      # Last attempt: do not swallow stderr, so the operator sees the real
      # failure instead of a possibly-wrong "not replicated yet" guess.
      if az ad sp create --id "$APP_ID" >/dev/null; then
        echo "    created service principal"
        break
      fi
      echo "    ERROR: service principal creation failed after retries (see error above)" >&2
      echo "    if it is a replication error, re-run this script; otherwise fix the cause" >&2
      exit 1
    fi
    if az ad sp create --id "$APP_ID" >/dev/null 2>&1; then
      echo "    created service principal"
      break
    fi
    echo "    sp create failed (attempt ${attempt}), retrying in $((attempt * 5))s..."
    sleep $((attempt * 5))
  done
fi
SP_OBJECT_ID="$(az ad sp show --id "$APP_ID" --query id -o tsv)"

# Federated credentials. Subject MUST match GitLab's OIDC `sub` claim exactly;
# audience MUST match id_tokens aud in .gitlab-ci.yml (api://AzureADTokenExchange).
add_fic () {
  local name="$1" subject="$2"
  echo "==> Federated credential: ${name}"
  echo "    subject=${subject}"
  if az ad app federated-credential show --id "$APP_ID" --federated-credential-id "$name" >/dev/null 2>&1; then
    echo "    already exists, skipping"
    return
  fi
  az ad app federated-credential create --id "$APP_ID" --parameters "$(cat <<JSON
{
  "name": "${name}",
  "issuer": "${GITLAB_ISSUER}",
  "subject": "${subject}",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
)" >/dev/null
  echo "    created"
}

add_fic "gitlab-main" \
  "project_path:${GITLAB_PROJECT_PATH}:ref_type:branch:ref:main"

if [ "$ADD_MR_CREDENTIAL" = "true" ]; then
  # MR pipelines run on the source branch, so the subject is per-branch and not
  # a single stable value. Azure GA federated credentials do not support
  # wildcards in subject, so there is no clean one-credential answer for MRs.
  # Preferred fix: make MR pipelines validate-only (no backend access) and leave
  # this false. See README "Merge request pipelines".
  echo "!!  ADD_MR_CREDENTIAL=true but MR subjects are per-branch; add one"
  echo "!!  federated credential per long-lived branch you plan from, e.g.:"
  echo "!!    project_path:${GITLAB_PROJECT_PATH}:ref_type:branch:ref:<branch>"
fi

echo "==> Granting Storage Blob Data Contributor on the state account"
SCOPE="/subscriptions/${BACKEND_SUBSCRIPTION_ID}/resourceGroups/${BACKEND_RESOURCE_GROUP}/providers/Microsoft.Storage/storageAccounts/${BACKEND_STORAGE_ACCOUNT}"
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "$SCOPE" >/dev/null
echo "    granted at ${SCOPE}"

cat <<SUMMARY

=============================================================================
Azure bootstrap complete. Set these GitLab CI/CD variables (non-secret ids):

  ARM_CLIENT_ID            ${APP_ID}
  ARM_TENANT_ID            ${TENANT_ID}
  BACKEND_SUBSCRIPTION_ID  ${BACKEND_SUBSCRIPTION_ID}

GitLab side (UI, cannot be scripted without an existing token):
  1. Top-level group > Settings > Access Tokens: create a GROUP access token,
     role Owner (or Maintainer), scope `api`, shortest workable expiry.
  2. Project (or group) > Settings > CI/CD > Variables: add
       GITLAB_TOKEN   = <the token>   (Masked, Protected)
       ARM_CLIENT_ID / ARM_TENANT_ID / BACKEND_SUBSCRIPTION_ID  (from above)
  3. Confirm SAML SSO is configured on the top-level group and the IdP emits
     group NAMES (not object-id GUIDs) in the groups claim.

Rotate GITLAB_TOKEN before expiry (see README "Rotating GITLAB_TOKEN").
=============================================================================
SUMMARY
