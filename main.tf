# # Module_blocks in root

# Create a Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.client}-data-platform-${var.environment}"
  location = var.region
}


# for tags
locals {
  default_tags = {
    owner       = var.owner
    environment = var.environment
    project     = var.project
    client      = var.client
    region      = var.region
    created_by  = "Terraform"
  }
}

module "network" {
  source              = "./modules/network"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
  region              = var.region
  project             = var.project
  environment         = var.environment
  default_tags        = local.default_tags
}

module "monitoring" {
  source              = "./modules/monitoring"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  region              = var.region
  client              = var.client
  environment         = var.environment
  alert_email         = var.alert_email
  default_tags        = local.default_tags
}

module "storage" {
  source              = "./modules/storage"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  region              = var.region
  vnet_id             = module.network.vnet_id
  vnet_name           = module.network.vnet_name
  subnet_id           = module.network.subnet_id
  client              = var.client
  environment         = var.environment
  containers          = var.containers
  default_tags        = local.default_tags
  log_analytics_id    = module.monitoring.log_analytics_id
  adls_logs           = var.adls_logs
  adls_rbac           = var.adls_rbac

  depends_on = [
    module.network,
    module.monitoring
  ]
}

module "dbx_workspace" {
  source = "./modules/dbx_workspace"
  providers = {
    databricks.create_workspace = databricks.create_workspace
  }
  client                  = var.client
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
  log_analytics_id        = module.monitoring.log_analytics_id
  dbx_logs                = var.dbx_logs
  dbx_rbac                = var.dbx_rbac

  depends_on = [
    module.network
    #module.monitoring
  ]
}

module "security" {
  source              = "./modules/security"
  client              = var.client
  environment         = var.environment
  region              = var.region
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  default_tags        = local.default_tags
  kv_rbac             = var.kv_rbac

  depends_on = [
    module.dbx_workspace,
    module.storage
  ]
}

module "unity_catalog" {
  source = "./modules/unity_catalog"
  providers = {
    databricks.workspace_resources = databricks.workspace_resources
  }

  client              = var.client
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  region              = var.region
  datalake_name       = module.storage.datalake_name
  datalake_id         = module.storage.datalake_id
  containers          = var.containers
  schemas             = var.schemas
  system_schemas      = var.system_schemas
  workspace_id        = module.dbx_workspace.workspace_id
  sqlw_max_clusters   = var.sqlw_max_clusters

  depends_on = [
    module.storage,
    module.dbx_workspace
  ]
}

# module "compute" {
#   source              = "./modules/compute"
#   count               = var.deploy_compute ? 1 : 0
#   client              = var.client
#   environment         = var.environment
#   region              = var.region
#   username            = var.username
#   resource_group_name = azurerm_resource_group.main.name
#   resource_group_id   = azurerm_resource_group.main.id
#   vnet_id             = module.network.vnet_id
#   vnet_name           = module.network.vnet_name
#   subnet_id           = module.network.subnet_id
#   public_subnet_id    = module.network.public_subnet_id
#   vm_private_ip       = var.vm_private_ip
#   key_vault_id        = module.security.key_vault_id
#   log_analytics_id    = module.monitoring.log_analytics_id
#   log_location        = module.monitoring.log_location

#   default_tags = merge(
#     local.default_tags,
#     {
#       "Environment" = "PROD"
#     }
#   )

#   depends_on = [
#     module.storage,
#     module.dbx_workspace,
#     module.unity_catalog,
#     module.security
#   ]
# }

# module "automation" {
#   source              = "./modules/automation"
#   count               = var.deploy_automation ? 1 : 0
#   client              = var.client
#   environment         = var.environment
#   region              = var.region
#   resource_group_name = azurerm_resource_group.main.name
#   resource_group_id   = azurerm_resource_group.main.id
#   vm_schedules        = var.vm_schedules

#   default_tags = local.default_tags

#   depends_on = [
#     module.storage,
#     module.dbx_workspace,
#     module.unity_catalog,
#     module.security,
#     module.compute
#   ]
# }

module "service_principal" {
  source              = "./modules/service_principal"
  client              = var.client
  environment         = var.environment
  resource_group_name = azurerm_resource_group.main.name
  key_vault_id        = module.security.key_vault_id
  datalake_id         = module.storage.datalake_id

  depends_on = [
    module.security,
    module.storage
  ]
}