############################################
# Application Insights (workspace-based)
############################################
resource "azurerm_application_insights" "this" {
  name                = "appi-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  workspace_id        = data.azurerm_log_analytics_workspace.this.id
  application_type    = "web"
  tags                = var.default_tags
}

############################################
# Storage Account — source documents for AI Search indexer
############################################
module "docs_storage" {
  source = "../../../../modules/storage"

  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  region              = var.region
  project             = "cyberparts"
  environment         = var.environment
  default_tags        = local.default_tags

  subnet_id        = azurerm_subnet.spoke["privateendpoints"].id
  vnet_id          = azurerm_virtual_network.spoke.id
  vnet_name        = azurerm_virtual_network.spoke.name
  log_analytics_id = data.azurerm_log_analytics_workspace.this.id

  containers = ["documents"]
  adls_rbac  = {}

  is_hns_enabled                  = false
  account_kind                    = "StorageV2"
  account_tier                    = "Standard"
  account_replication_type        = var.replication
  public_network_access_enabled   = false
  allow_nested_items_to_be_public = false
  pe_subresource_names            = ["blob"]
  private_dns_zone_ids            = [data.azurerm_private_dns_zone.blob.id]
  create_private_endpoint         = true

}

# resource "azurerm_private_endpoint" "st" {
#   name                = "pe-st-cyberparts-${var.environment}"
#   resource_group_name = azurerm_resource_group.main.name
#   location            = var.region
#   subnet_id           = azurerm_subnet.spoke["privateendpoints"].id
#   tags                = local.default_tags

#   private_service_connection {
#     name                           = "stconnection"
#     private_connection_resource_id = module.docs_storage.id
#     subresource_names              = ["blob"]
#     is_manual_connection           = false
#   }

#   private_dns_zone_group {
#     name                 = "storage-dns"
#     private_dns_zone_ids = [data.azurerm_private_dns_zone.blob.id]
#   }
# }

data "azurerm_client_config" "current" {}
