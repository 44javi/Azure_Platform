# GitLab Org Structure

Terraform module that manages the GitLab group hierarchy, Entra ID SAML group
links, and group CI/CD variables on GitLab.com SaaS. The naming is parameterized
by an organization prefix (`company_abbr`), so the module applies to any
organization without code changes.

## Prerequisites

- An existing GitLab.com **top-level group** (created at signup, tied to
  billing and SAML/SCIM). This module references it as a data source and never
  creates or destroys it.
- A **GitLab group access token** scoped to the top-level group, `api` scope.
  Exported as `GITLAB_TOKEN`. The token's bot/service account must be a direct
  member of the top-level group with sufficient access to read the group and
  manage the resources in this module. Never commit it.
- **SAML SSO** configured on the top-level group, and the IdP set to emit group
  **names** (not object-id GUIDs) in the SAML groups claim. The `saml_group_name`
  values this module creates must match what the IdP sends.
- Azure access to the **management storage account** for Terraform state
  (`az login` locally; OIDC federated credential in CI).
- Terraform >= 1.5. The `gitlabhq/gitlab` provider major is pinned in
  `versions.tf`; verify the latest stable and run `terraform init -upgrade`
  once to write the lock file.

## Architecture

```
{company} (top-level group, pre-existing)   <- data source
├── iam          <- gitlab_group
├── cloud
├── networking
├── security
└── data
```

GitLab's hierarchy is: top-level group (the billing/SAML boundary on SaaS) ->
subgroups (departments) -> projects. Settings, members, CI/CD variables, and
runners attached to a group **inherit downward**. This module puts department
subgroups under the existing top-level group and drives access through Entra ID
group links rather than per-user membership.

### Naming convention

Entra ID security groups follow:

```
{COMPANY}-{SYSTEM}-{DOMAIN}-{ROLE}     e.g. ACME-GL-CLOUD-ENG
```

| Segment | Source | Purpose | Examples |
|---------|--------|---------|----------|
| COMPANY | `company_abbr` (uppercased) | Tenant key; isolates one company and avoids collisions with pre-existing groups | `ACME`, `CN` |
| SYSTEM  | `system_segment` | What the group grants | `GL` (GitLab), `AZ` (Azure RBAC) |
| DOMAIN  | `departments[*].saml_token` | Department / subgroup | `IAM`, `CLOUD`, `NET`, `SEC`, `DATA`, `PLATFORM` |
| ROLE    | role tier | Permission level | `ADMIN`, `LEAD`, `ENG`, `AUDIT` |

The `COMPANY` and `SYSTEM` segments are what protect you in a brownfield
tenant: a pre-existing `Data` or `Networking` group cannot collide with
`ACME-GL-DATA-ENG`, and the `GL`/`AZ` split keeps GitLab role groups distinct
from Azure RBAC groups. Filtering Entra by `ACME-` or `ACME-GL-` gives an
instant inventory of every group this module manages.

### GitLab built-in roles (reference)

The five GitLab roles, least to most privileged:

| Role | Can do |
|------|--------|
| Guest | View issues, view public/internal project metadata. No code access on private projects. |
| Reporter | Read code, pipelines, and issues. No push, no merge. |
| Developer | Push to non-protected branches, open merge requests, run pipelines, push container/package images. |
| Maintainer | Everything Developer can, plus manage project settings, protected branches, merge to protected branches, manage variables. |
| Owner | Everything Maintainer can, plus manage group membership and settings, and delete the group. Group level only. |

### Role tiers (this module)

`role_to_access` maps the `ROLE` segment onto a GitLab role:

| ROLE | GitLab role | Can do | Use for |
|------|-------------|--------|---------|
| ADMIN | Owner | Manage the group, members, settings, delete | Platform/IAM team only, at the top-level group |
| LEAD | Maintainer | Manage projects, protected branches, merge to protected | Department leads |
| ENG | Developer | Push to feature branches, open MRs, run pipelines | Day-to-day engineers |
| AUDIT | Reporter | Read code and pipelines, no write | Security/compliance read-only |

`LEAD` is deliberately Maintainer, not Owner: Owner can delete the group and
rewrite membership, so it is reserved for platform admins and IAM. Bump a
specific department to Owner only if it genuinely self-administers.

### Group set for one company (COMPANY=ACME)

Generated from the default `departments` and `top_level_saml_links`:

| Entra ID group | GitLab target | Role |
|----------------|---------------|------|
| `ACME-GL-PLATFORM-ADMIN` | `acme/` (top) | Owner |
| `ACME-GL-IAM-LEAD` | `acme/iam` | Maintainer |
| `ACME-GL-IAM-ENG` | `acme/iam` | Developer |
| `ACME-GL-CLOUD-LEAD` | `acme/cloud` | Maintainer |
| `ACME-GL-CLOUD-ENG` | `acme/cloud` | Developer |
| `ACME-GL-NET-LEAD` | `acme/networking` | Maintainer |
| `ACME-GL-NET-ENG` | `acme/networking` | Developer |
| `ACME-GL-SEC-LEAD` | `acme/security` | Maintainer |
| `ACME-GL-SEC-ENG` | `acme/security` | Developer |
| `ACME-GL-SEC-AUDIT` | `acme/` (top) | Reporter (read-only across all departments) |
| `ACME-GL-DATA-LEAD` | `acme/data` | Maintainer |
| `ACME-GL-DATA-ENG` | `acme/data` | Developer |

`SEC-AUDIT` is linked at the top-level group so a single inherited Reporter
grant gives security read-only visibility into every department.

Membership is owned by the IdP (SAML/SCIM). This module only defines what each
mapped group can do; do not also add direct members or they fight on drift.

### Configure SAML SSO with Microsoft Entra ID

SAML SSO is configured once on the GitLab.com top-level group. SAML Group Links
can then be attached to the top-level group or to department subgroups by this
Terraform module.

1. In GitLab, open the top-level group and go to **Settings > SAML SSO**.
   Record these GitLab service provider values:

   | GitLab value | Microsoft Entra field |
   |--------------|------------------------|
   | Identifier | Identifier (Entity ID) |
   | Assertion consumer service URL | Reply URL (Assertion Consumer Service URL) |
   | GitLab single sign-on URL | Sign on URL |

2. In Microsoft Entra admin center, create an Enterprise Application:
   **Enterprise applications > New application > Create your own application**.
   Choose a non-gallery application, then open **Single sign-on > SAML**.

3. In **Basic SAML Configuration**, enter the GitLab values from the previous
   step. Leave Logout URL and Relay State blank unless the organization has a
   specific requirement for them.

4. In **Attributes & Claims**, set the Name ID:

   | Claim setting | Value |
   |---------------|-------|
   | Unique User Identifier (Name ID) | `user.objectid` |
   | Name identifier format | `Persistent` |

   Also emit user attributes for email, first name, and last name. The exact
   source attributes can vary by tenant, but `user.mail` or
   `user.userprincipalname`, `user.givenname`, and `user.surname` are typical.

5. Add a group claim for GitLab Group Sync:

   - Select **Groups assigned to the application**.
   - For cloud-only Entra groups, use **Cloud-only group display names** so the
     assertion can emit names like `ACME-GL-CLOUD-ENG`.
   - In advanced options, customize the group claim name to `Groups` with no
     namespace.

   GitLab accepts `Groups` or `groups` as the group sync attribute name. URI
   claim names such as
   `http://schemas.microsoft.com/ws/2008/06/identity/claims/groups` are not
   accepted by GitLab Group Sync.

   The emitted group values must exactly match the Terraform-generated
   `saml_group_name` values. If Entra emits object IDs instead of display names,
   set the Terraform SAML group names to those object IDs instead.

6. In the Entra Enterprise Application, open **Users and groups** and assign:

   - The users who should sign in through GitLab SAML.
   - The Entra security groups this module expects, for example
     `{COMPANY}-GL-CLOUD-ENG`, `{COMPANY}-GL-CLOUD-LEAD`, and
     `{COMPANY}-GL-PLATFORM-ADMIN`.

   When using **Groups assigned to the application**, only directly assigned
   groups are emitted. Nested groups are not included.

7. In Entra's SAML configuration page, copy the **Login URL** and download the
   SAML signing certificate. Generate the SHA1 certificate fingerprint:

   ```bash
   openssl x509 -noout -fingerprint -sha1 -inform pem -in <downloaded-cert-file>
   ```

8. Back in GitLab **Settings > SAML SSO**, enter:

   | GitLab field | Entra value |
   |--------------|-------------|
   | Identity provider single sign-on URL | Login URL |
   | Certificate fingerprint | SHA1 fingerprint from the signing certificate |

   Set the default membership role to the least privileged option available,
   enable SAML authentication for the group, and save. Test SAML sign-in before
   enforcing SSO-only authentication.

9. Run Terraform after SAML SSO is enabled. The
   `gitlab_group_saml_link` resources create the SAML Group Links that map Entra
   groups to GitLab roles.

Sources:

- GitLab SAML SSO for GitLab.com groups:
  <https://docs.gitlab.com/user/group/saml_sso/>
- GitLab SAML Group Sync and SAML Group Links:
  <https://docs.gitlab.com/user/group/saml_sso/group_sync/>
- Microsoft Entra SAML application configuration:
  <https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/add-application-portal-setup-sso>
- Microsoft Entra group claims:
  <https://learn.microsoft.com/en-us/entra/identity/hybrid/connect/how-to-connect-fed-group-claims>

## Bootstrap (one-time)

Two credentials are in play, and they are not equally secretless:

- **State backend (CI): secretless.** GitLab mints an OIDC token (`id_tokens`),
  Azure trusts it through a federated credential, and Terraform exchanges it
  (`ARM_USE_OIDC`). No Azure secret is stored.
- **GitLab provider: needs a token.** GitLab does not accept its own OIDC token
  to authenticate the Terraform provider, and `CI_JOB_TOKEN` cannot manage
  groups, SAML links, or group variables. So a group access token (`api` scope)
  is required. There is no fully secretless option today; the realistic answer
  is to rotate it (see below).

The pipeline needs an Azure identity before
it can run, so that identity is created by
`bootstrap.sh` :

```bash
az login   # as someone who can create app registrations and assign roles
export COMPANY_ABBR=<org-prefix>
export GITLAB_PROJECT_PATH=<group/subgroup/project>
export BACKEND_SUBSCRIPTION_ID=<state-subscription-id>
export BACKEND_RESOURCE_GROUP=<state-resource-group>
export BACKEND_STORAGE_ACCOUNT=<state-storage-account>
chmod +x ./bootstrap.sh
./bootstrap.sh
```

It creates the app registration + service principal (the "state SP"), adds a
federated credential trusting GitLab's OIDC token for `main`, grants the SP
`Storage Blob Data Contributor` on the state storage account, and prints the
`ARM_CLIENT_ID` / `ARM_TENANT_ID` / `BACKEND_SUBSCRIPTION_ID` values to paste
into GitLab.

The script then lists the **GitLab-side steps that cannot be scripted** without
an existing token: create the first `GITLAB_TOKEN` group access token, add the
token's bot/service account as a direct member of the top-level group, set the
CI/CD variables, and confirm SAML SSO emits group names. After this one-time
setup, everything else is Terraform.

### Merge request pipelines

The federated credential created by `bootstrap.sh` matches only
`...:ref:main`. MR pipelines run on the source branch, so their OIDC subject is
per-branch, and Azure GA federated credentials do not support wildcards in the
subject. Two options:

- **Recommended:** keep MR pipelines validate-only (`fmt` + `validate` with
  `-backend=false`, no backend access, no credential needed) and run `plan` only
  on `main`. This avoids per-branch credentials entirely.
- Otherwise add one federated credential per long-lived branch you plan from
  (set `ADD_MR_CREDENTIAL=true` and extend the script). This does not scale to
  arbitrary feature branches.

Note: `.gitlab-ci.yml` currently runs `plan` on `merge_request_event`, which
touches the backend. Reconcile it with whichever option you pick.

### Rotating GITLAB_TOKEN

Group access tokens expire (GitLab caps the lifetime). Rotate before expiry so a
pipeline never 401s on a dead token:

- **Self-rotation (recommended).** A scheduled pipeline calls the rotate
  endpoint, which issues a new token and revokes the old one, then writes the new
  value back into the CI/CD variable. Run it well before expiry (e.g. weekly) so
  the token rotates itself and never goes stale:

  ```bash
  # authenticated with the current GITLAB_TOKEN
  GROUP_ID=<top-level group id>
  TOKEN_ID=<this token's id>
  NEW=$(curl -sf --request POST \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "https://gitlab.com/api/v4/groups/$GROUP_ID/access_tokens/$TOKEN_ID/rotate?expires_at=$(date -d '+30 days' +%F)" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
  # write $NEW back into the GITLAB_TOKEN CI/CD variable
  curl -sf --request PUT \
    --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "https://gitlab.com/api/v4/groups/$GROUP_ID/variables/GITLAB_TOKEN" \
    --form "value=$NEW" >/dev/null
  ```

  Verify the rotate endpoint behavior against your GitLab tier before relying on
  it.
- **Manual.** Generate a new group access token in the UI and paste it into the
  `GITLAB_TOKEN` CI/CD variable before the old one expires.

## Deployment

State lives in the management storage account. Auth differs by context: the
GitLab provider always uses `GITLAB_TOKEN`; the state backend uses `az login`
locally and OIDC in CI.

### Local

```bash
az login
export GITLAB_TOKEN=<group-access-token>
export BACKEND_SUBSCRIPTION_ID=<state-subscription-id>
export BACKEND_RESOURCE_GROUP=<state-resource-group>
export BACKEND_STORAGE_ACCOUNT=<state-storage-account>
export BACKEND_STORAGE_CONTAINER=<state-container>
chmod +x ./.debug.global.sh
./.debug.global.sh plan
./.debug.global.sh apply
```

`.debug.global.sh` sets the backend key (`gitlab-global`) and runs against
`env/global.tfvars`. Before planning, set `company_abbr` and
`top_level_group_path` in `env/global.tfvars` to the target organization and
the exact existing GitLab top-level group URL path.

### CI (GitLab)

`.gitlab-ci.yml` runs validate -> plan -> apply (manual) -> destroy (manual).
Point the project CI config at it: Settings > CI/CD > General pipelines >
CI/CD configuration file = `platform/gitlab/.gitlab-ci.yml`. Set the CI/CD
variables and Azure federated credential documented in that file's header.
Set `company_abbr` and `top_level_group_path` in `env/global.tfvars` before
enabling the pipeline.

## Validation

```bash
terraform fmt -check -recursive
terraform validate

# list the exact Entra ID groups that must exist for access to work
terraform output required_entra_groups
```

After apply, confirm in GitLab: the department subgroups exist under the
top-level group, and each subgroup's Settings > SAML Group Links show the
expected `{COMPANY}-{SYSTEM}-{DOMAIN}-{ROLE}` names.

## Troubleshooting

- **Users get no access after SAML login.** The IdP is almost certainly
  emitting group object-id GUIDs instead of names. Either reconfigure the
  groups claim to send names, or set `saml_group_name` to the GUIDs. Compare
  `terraform output required_entra_groups` against the assertion.
- **`data.gitlab_group.top` not found.** `top_level_group_path` is wrong, or
  `GITLAB_TOKEN` lacks access to it. Confirm the token's bot/service account is
  a direct member of the top-level group. The path is the group's URL slug.
- **401/403 from the provider.** `GITLAB_TOKEN` missing, expired, or wrong
  scope (needs `api`). Group access tokens expire; rotate before expiry.
- **Backend auth fails in CI.** The federated credential subject must match
  the running ref (`project_path:<group>/<project>:ref_type:branch:ref:main`),
  and the SP needs Storage Blob Data Contributor on the state account.
- **SCIM drift.** If SCIM provisions membership, keep Terraform to SAML links
  only. Do not manage `gitlab_group_membership` on SCIM-managed groups.
