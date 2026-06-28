# Public Landing Zone Infrastructure

Terraform provisions the public workload resources for this landing zone,
including AI Foundry, AI Search, storage, Cosmos DB, networking, monitoring,
and RBAC. Operational cleanup for lab subscriptions is handled by
`cleanup.sh`, not by Terraform destroy.

## Prerequisites

- Azure access to the target subscription and any referenced management or
  connectivity subscriptions.
- Terraform credentials and backend configuration supplied by automation or by
  the engineer running Terraform locally.
- GitLab CI/CD variables for scheduled lab cleanup:
  `ARM_CLIENT_ID`, `ARM_TENANT_ID`, and `LAB_SUBSCRIPTION_ID`.
- A federated credential on the Azure app registration that trusts GitLab OIDC
  for the project and branch that runs the scheduled pipeline.
- Cleanup identity RBAC:
  Contributor on the lab subscription, plus provider-specific purge permissions
  where soft-deleted services must be purged.
- `az`, `jq`, and Bash for running `cleanup.sh` manually.

## Architecture

Terraform creates application resources in a workload resource group named from
the `project` and `environment` variables. Shared management and connectivity
resources are referenced through separate provider configurations.

The lab cleanup path is intentionally separate from Terraform state. A
scheduled GitLab pipeline authenticates to Azure with OIDC, runs `cleanup.sh`,
queries ARM resources with `$expand=createdTime`, and deletes resources older
than the configured TTL. This avoids Terraform destroy ordering issues for
services that may create managed or dependent resources outside Terraform's
direct control.

Cleanup behavior:

- Default TTL is `90` days.
- `TTL_HOURS` overrides `TTL_DAYS` for short testing windows.
- `DRY_RUN=true` reports resources without deleting them.
- Resources or resource groups tagged `ttl=keep` are exempt.
- Managed resource groups are skipped and are expected to disappear when their
  parent resource is deleted.
- Locks are removed when `DRY_RUN=false` so cleanup cannot be permanently
  blocked in a lab subscription.
- Soft-deleted Key Vault, Cognitive Services or AI Foundry, API Management,
  and App Configuration resources are purged where Azure permits it.

## Deployment

The engineer runs Terraform commands for infrastructure deployment:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

Configure the GitLab project to use this CI file or include it from a root
pipeline. Create a scheduled pipeline for the lab cleanup job and set schedule
variables as needed:

```text
TTL_DAYS=90
DRY_RUN=true
```

For a short test window, set `TTL_HOURS` on the schedule or manual pipeline:

```text
TTL_HOURS=2
DRY_RUN=true
```

After reviewing dry-run output, set `DRY_RUN=false` for deletion.

## Validation

After Terraform deployment:

1. Approve pending shared private link connections for AI Search to reach
   Foundry and storage.
2. Wait for private DNS propagation before testing Search indexers or Foundry
   agent retrieval.
3. Bootstrap the Foundry agent from inside the spoke network when required:

   ```bash
   TF_VAR_project=<project> TF_VAR_environment=<environment> \
   SEARCH_CONNECTION_NAME=<project-connection> SEARCH_INDEX_NAME=<index> \
   MODEL=agent python agent_bootstrap.py
   ```

4. Verify AI Search indexers complete successfully and documents are indexed.
5. Test the agent in Foundry with an organization-specific prompt.

For cleanup validation:

1. Run the GitLab cleanup pipeline with `DRY_RUN=true`.
2. Confirm the subscription name guard matches the intended lab subscription.
3. Confirm only expected resources appear in the expired resource list.
4. Set a short `TTL_HOURS` value for test resources before enabling
   `DRY_RUN=false`.

## Troubleshooting

- If cleanup refuses to run, verify the subscription display name matches
  `SUBSCRIPTION_NAME_GUARD` or explicitly set `ALLOW_ANY_SUBSCRIPTION=true`
  for a controlled test.
- If resources survive cleanup, review the final leftover list. Dependency
  ordering may require increasing `MAX_PASSES` or `PASS_WAIT_SECONDS`.
- If Key Vault purge is skipped, purge protection is enabled and Azure will not
  allow immediate purge.
- If Foundry or Cognitive Services names remain unavailable, verify the cleanup
  identity has permission to list and purge deleted Cognitive Services
  accounts.
- If GitLab authentication fails, verify the app registration federated
  credential issuer, subject, and audience match the GitLab job token.
