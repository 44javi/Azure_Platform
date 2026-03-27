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