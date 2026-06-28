# Azure Platform

Terraform monorepo automating our Azure tenant. Aligned to Azure Landing Zones (CAF).

## Engagement model

- Cybernetic Nimbus is a consultancy. This code is handed over to the client and runs in the client's tenant and GitLab. We do not manage another company's resources from our own tenant. Our own tenant is for demos only.
- Write all code to be portable and parameterized for handover: company/tenant/org values as variables, no Cybernetic Nimbus identifiers hardcoded.
- Documentation (README.md, Confluence) must be client-agnostic and applicable to any company we work with. Do not mention Cybernetic Nimbus, the consultancy relationship, or a multi-client/"as a service" framing in docs. Write as if for the single client org deploying it.

## Repo layout

- `platform/` - core platform: `management/` (centralized resources: monitoring, governance) and `connectivity/` (networking)
- `landing_zones/` - deployable workloads: `private/` (internal, e.g. data_platform) and `public/` (e.g. cyber_parts)
- `modules/` - reusable Terraform modules consumed by platform and landing zones
- `env/` - environment tfvars (currently `prod.tfvars`)

## Conventions

- Centralized or platform-wide resources belong in `platform/management/`, not in `modules/`.
- New resources: prefer extending an existing module over inline resources in a landing zone.
- Secret management: consider Azure Key Vault first for secrets. For every secret, consider rotation behavior; if Key Vault is not ideal, explain why and offer alternatives.
- Local `.debug.<env>.sh` scripts, for example `.debug.dev.sh`, `.debug.test.sh`, `.debug.qa.sh`, `.debug.uat.sh`, `.debug.prod.sh`, and `.debug.global.sh`, are for local testing only and must not be committed. Automation is the target execution path, and local scripts and automation must stay compatible so testing mirrors CI/CD behavior.
- The engineer runs `terraform fmt`, `terraform validate`, `terraform plan`, and `terraform apply`/`destroy`, not the agent. The agent writes and edits the Terraform; the engineer runs the Terraform CLI.

## Production changes

- Never run `terraform apply` or any mutating `az` command against prod. Read-only `az` commands for diagnosis are fine.
- Diagnose and provide the fix; the engineer applies it.

## Technology choices

- GA features only. Never build on Preview, Beta, or experimental Azure features or provider resources without explicit approval. Flag it clearly if a solution would require one.
- No deprecated or end-of-support services, APIs, or patterns. If you find one in the codebase, recommend the modern replacement.
- Infrastructure as Code over portal changes whenever practical.
- Bash for scripts, never PowerShell unless explicitly requested or Windows-only.

## Communication

- Concise and clear, neutral professional tone. No em dashes.
- State assumptions, risks, and security implications for architectural recommendations. Say when something needs verification rather than presenting it as fact.
- Ask before making architectural decisions when requirements are ambiguous.
- Documentation as README.md with headings: prerequisites, architecture, deployment, validation, troubleshooting.
