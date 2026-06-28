# Source Control Structure as Code

Provisions the source-control org layout (subgroups/projects, repos, branch
policies, and CI/CD variables) as Terraform, so the structure is version
controlled and reproducible across providers.

One logical model is realized by a provider-specific module. GitLab is
implemented; Azure DevOps and GitHub are stubbed with the same variable
interface, so a deployment switches providers by changing only the module
source.

## Prerequisites

- Terraform >= 1.5.
- The top-level container already exists and is referenced, never created:
  - GitLab: top-level group (created at signup, tied to billing/SAML).
  - Azure DevOps: organization.
  - GitHub: organization.
- Provider credentials exported in the environment (nothing committed):
  - GitLab: `GITLAB_TOKEN` (PAT or group access token, `api` scope). For
    self-managed, also `GITLAB_BASE_URL`.
  - Azure DevOps: `AZDO_ORG_SERVICE_URL`, `AZDO_PERSONAL_ACCESS_TOKEN`.
  - GitHub: `GITHUB_OWNER`, `GITHUB_TOKEN` (a GitHub App install token is
    preferred over a PAT for rotation).
- Remote state backend for the deployment (same pattern as the Azure roots).

## Architecture

```
scm/
  modules/
    scm_gitlab/        # implemented: subgroups, projects, branch policy,
                       #   approvals, CI variables, seeded pipeline
    scm_azuredevops/   # stub, same interface
    scm_github/        # stub, same interface
  deployments/
    acme/              # one deployment per client; selects a provider module
      main.tf
      departments.auto.tfvars   # the editable org structure
```

Logical model and how each provider realizes it:

| Model    | GitLab          | Azure DevOps        | GitHub                     |
|----------|-----------------|---------------------|----------------------------|
| department | subgroup      | project (container) | repo prefix + team         |
| repo     | project         | git repo in project | repo                       |
| protected | protected branch | branch policy      | branch protection          |
| reviewers | approval rule  | min-reviewers policy| required PR reviews        |
| ci_variables | group variable | variable group    | Actions variable           |

The top-level container is the root the modules build under. It cannot be
created by Terraform on any of the three providers, so it is a one-time manual
bootstrap.

## Deployment

The engineer runs the Terraform; values below are the editable inputs.

1. Edit the org structure in `deployments/<client>/departments.auto.tfvars`.
   Each `departments` entry is one subgroup. For a small org, delete the blocks
   you do not need (for example `security` or `networking`); to add one, copy a
   block. Nothing else changes.
2. Export the provider credentials (see Prerequisites).
3. From `deployments/<client>`:

   ```bash
   terraform init   # add -backend-config=... for remote state
   terraform plan
   terraform apply
   ```

To target a different provider, change the `module "scm"` source in
`main.tf` to `../../modules/scm_azuredevops` or `../../modules/scm_github`.
The input variables are identical.

## Validation

- `terraform plan` shows the expected subgroups, projects, branch protections,
  approval rules, and group variables, with no unexpected deletes against the
  top-level group (it must stay a data source).
- After apply, `terraform output repo_ssh_urls` lists clone URLs for each repo.
- Spot-check in the provider UI: subgroup nesting, default branch protected,
  required approvals, and that group CI variables are present and masked where
  expected.

## Troubleshooting

- `404` / `403` on the top-level group: the token lacks access, or
  `top_level_group` does not match the existing path. The module references it;
  it does not create it.
- CI file seeding fails: the project needs an initialized default branch. The
  module sets `initialize_with_readme = true`; confirm the branch in the tfvars
  matches the project default.
- Drift on a seeded `.gitlab-ci.yml`: expected and ignored. The module sets
  `ignore_changes = [content]` so teams own the file after creation.
- Group variable shows as plain text: `masked = true` requires a value that
  satisfies GitLab masking rules. IDs (tenant/subscription) are not secrets and
  are fine unmasked; real secrets belong in Key Vault, not here.
