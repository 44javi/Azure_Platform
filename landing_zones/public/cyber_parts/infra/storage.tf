############################################
# Application Insights (workspace-based)
############################################
resource "azurerm_application_insights" "this" {
  name                = "appi-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  workspace_id        = var.log_analytics_workspace_id
  application_type    = "web"
  tags                = var.default_tags
}

############################################
# Key Vault — RBAC mode, no public access
############################################
resource "azurerm_key_vault" "this" {
  name                          = "kv-${var.project}-${var.environment}"
  resource_group_name           = var.resource_group_name
  location                      = var.region
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  enable_rbac_authorization     = true
  public_network_access_enabled = false
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  tags                          = var.default_tags
}

resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-kv-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.default_tags

  private_service_connection {
    name                           = "psc-kv-${var.project}-${var.environment}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids.key_vault]
  }
}

############################################
# Storage Account — source documents for AI Search indexer
############################################
resource "azurerm_storage_account" "docs" {
  name                          = replace("st${var.project}docs${var.environment}", "-", "")
  resource_group_name           = var.resource_group_name
  location                      = var.region
  account_tier                  = "Standard"
  account_replication_type      = "LRS"
  account_kind                  = "StorageV2"
  https_traffic_only_enabled    = true
  min_tls_version               = "TLS1_2"
  public_network_access_enabled = false
  shared_access_key_enabled     = false # force AAD/managed identity auth
  tags                          = var.default_tags
}

resource "azurerm_storage_container" "documents" {
  name                  = "documents"
  storage_account_id    = azurerm_storage_account.docs.id
  container_access_type = "private"
}

resource "azurerm_private_endpoint" "storage_blob" {
  name                = "pe-st-blob-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.default_tags

  private_service_connection {
    name                           = "psc-st-blob-${var.project}-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.docs.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids.blob]
  }
}

data "azurerm_client_config" "current" {}