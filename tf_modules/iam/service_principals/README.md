# Service Principal Module

Creates an Entra ID application, service principal, optional credential, and
Azure role assignments. Supported credential modes are:

- `secret`: creates an application password and stores it in Key Vault.
- `certificate`: creates a self-signed Key Vault certificate and adds it to the application.
- `federated`: creates workload identity federation credentials, for example GitLab OIDC.

## Requirements

The root module must configure these providers:

```hcl
terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
    azurerm = {
      source = "hashicorp/azurerm"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
```

The identity running Terraform needs permission to create Entra applications,
service principals, application credentials, and any requested Azure role
assignments.

## Secret Credential

```hcl
module "app_sp" {
  source = "../../../modules/service_principal"

  project              = "app"
  environment          = var.environment
  resource_group_name  = azurerm_resource_group.main.name
  credential_type      = "secret"
  key_vault_id         = azurerm_key_vault.main.id
  secret_rotation_days = 90

  role_assignments = {
    contributor = {
      scope                = azurerm_resource_group.main.id
      role_definition_name = "Contributor"
    }
  }
}
```

Use `module.app_sp.application_client_id` as the client ID. The generated
secret is stored in Key Vault and exposed through `client_secret_name` and
`client_secret_id`.

## Certificate Credential

```hcl
module "cert_sp" {
  source = "../../../modules/service_principal"

  project             = "app"
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  credential_type     = "certificate"
  key_vault_id        = azurerm_key_vault.main.id
}
```

Use `certificate_name`, `key_vault_certificate_id`, or `certificate_secret_id`
to locate the certificate material in Key Vault.

## GitLab Federated Credential

Use this mode for secretless GitLab CI/CD authentication to Azure.

```hcl
module "gitlab_cleanup_sp" {
  source = "../../../modules/service_principal"

  project             = "cleanup"
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  credential_type     = "federated"

  federated_identity_credentials = {
    gitlab_main = {
      display_name = "gitlab-main"
      issuer       = "https://gitlab.com"
      subject      = "project_path:<group>/<project>:ref_type:branch:ref:main"
      audiences    = ["api://AzureADTokenExchange"]
    }
  }

  role_assignments = {
    subscription_contributor = {
      scope                = "/subscriptions/${var.subscription_id}"
      role_definition_name = "Contributor"
    }
  }
}
```

For self-managed GitLab, set `issuer` to your GitLab instance URL. Match
`subject` to the exact branch, tag, or environment that will request the OIDC
token.

Set these GitLab CI/CD variables from module outputs:

```text
ARM_CLIENT_ID = module.gitlab_cleanup_sp.application_client_id
ARM_TENANT_ID = module.gitlab_cleanup_sp.tenant_id
```

Your GitLab job must request an ID token with this audience:

```yaml
id_tokens:
  AZURE_OIDC_TOKEN:
    aud: api://AzureADTokenExchange
```

## Inputs

| Name | Required | Description |
| --- | --- | --- |
| `project` | yes | Name segment used for the application and credential names. |
| `environment` | yes | Environment name segment used for naming. |
| `resource_group_name` | yes | Resource group name passed to the module for compatibility. |
| `credential_type` | no | `secret`, `certificate`, or `federated`. Defaults to `secret`. |
| `key_vault_id` | for `secret` or `certificate` | Key Vault that stores generated secret or certificate material. |
| `secret_rotation_days` | no | Rotation interval for `secret` credentials. Defaults to `90`. |
| `federated_identity_credentials` | for `federated` | Map of federated identity credential definitions. |
| `role_assignments` | no | Map of Azure role assignments for the service principal. |
| `default_tags` | no | Retained for interface consistency. |
| `datalake_id` | no | Retained for interface consistency. |

## Outputs

| Name | Description |
| --- | --- |
| `application_client_id` | Client/application ID. Use as `ARM_CLIENT_ID`. |
| `application_object_id` | Entra application object ID. |
| `service_principal_object_id` | Service principal object ID used for role assignments. |
| `tenant_id` | Tenant ID. Use as `ARM_TENANT_ID`. |
| `client_secret_name` / `client_secret_id` | Key Vault secret outputs for `secret` mode. |
| `certificate_name` / `key_vault_certificate_id` / `certificate_secret_id` | Key Vault certificate outputs for `certificate` mode. |
| `federated_identity_credential_ids` | Resource IDs for federated credentials. |
| `federated_identity_credential_credential_ids` | Federated credential UUIDs. |
