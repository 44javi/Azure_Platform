# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.region
}

module "network" {
  source              = "../../../modules/network"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
  region              = var.region
  project             = var.project
  environment         = var.environment
  default_tags        = local.default_tags
}

data "azurerm_log_analytics_workspace" "management" {
  provider            = azurerm.management
  name                = var.log_analytics_workspace_name
  resource_group_name = var.log_analytics_resource_group
}

module "storage" {
  source              = "../../../modules/storage"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  region              = var.region
  vnet_id             = module.network.vnet_id
  vnet_name           = module.network.vnet_name
  subnet_id           = module.network.subnet_id
  project             = var.project
  environment         = var.environment
  containers          = var.containers
  default_tags        = local.default_tags
  adls_logs           = var.adls_logs
  adls_rbac           = var.adls_rbac
  log_analytics_id    = data.azurerm_log_analytics_workspace.management.id

  depends_on = [
    module.network
  ]
}

module "dbx_workspace" {
  source = "../../../modules/dbx_workspace"
  providers = {
    databricks.create_workspace = databricks.create_workspace
  }
  project                 = var.project
  resource_group_name     = azurerm_resource_group.main.name
  region                  = var.region
  environment             = var.environment
  default_tags            = local.default_tags
  subnet_address_prefixes = var.subnet_address_prefixes
  vnet_id                 = module.network.vnet_id
  vnet_name               = module.network.vnet_name
  subnet_id               = module.network.subnet_id
  public_ip_id            = module.network.public_ip_id
  nat_gateway_id          = module.network.nat_gateway_id
  dbx_logs                = var.dbx_logs
  dbx_rbac                = var.dbx_rbac
  log_analytics_id        = data.azurerm_log_analytics_workspace.management.id

  depends_on = [
    module.network
  ]
}

module "dbx_resources" {
  source = "../../../modules/dbx_resources"
  providers = {
    databricks.workspace_resources = databricks.workspace_resources
  }

  project             = var.project
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  region              = var.region
  datalake_name       = module.storage.name
  datalake_id         = module.storage.id
  containers          = var.containers
  schemas             = var.schemas
  workspace_id        = module.dbx_workspace.workspace_id

  depends_on = [
    module.storage,
    module.dbx_workspace
  ]
}

data "azurerm_key_vault" "management" {
  provider            = azurerm.management
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group
}

module "sat_sp" {
  source              = "../../../modules/service_principal"
  project             = "sat"
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  key_vault_id        = data.azurerm_key_vault.management.id
}

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
      subject      = "project_path:cybernetic-nimbus-group/cloud/cyber-parts:ref_type:branch:ref:main"
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
