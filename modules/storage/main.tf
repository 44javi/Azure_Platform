# data_resources module

# Get Azure subscription details
data "azurerm_client_config" "current" {}

data "azuread_group" "adls_groups" {
  for_each     = var.adls_rbac
  display_name = each.value.group_name
}

# Random string for storage names
resource "random_string" "this" {
  length  = 2
  special = false
  upper   = false
  lower   = false
  numeric = true
}

# Data Lake Storage
resource "azurerm_storage_account" "adls" {
  name                            = "adls${var.project}${var.environment}${random_string.this.result}"
  resource_group_name             = var.resource_group_name
  location                        = var.region
  min_tls_version                 = var.min_tls_version
  https_traffic_only_enabled      = var.https_traffic_only_enabled
  account_tier                    = var.account_tier
  account_replication_type        = var.account_replication_type
  account_kind                    = var.account_kind
  is_hns_enabled                  = var.is_hns_enabled
  allow_nested_items_to_be_public = var.allow_nested_items_to_be_public
  public_network_access_enabled   = var.public_network_access_enabled #false blocks access to containers on the portal
  #shared_access_key_enabled = false

  tags = var.default_tags

  blob_properties {
    delete_retention_policy {
      days = var.st_retention_days
    }

    container_delete_retention_policy {
      days = var.st_retention_days
    }
  }

}

# Containers for 

resource "azurerm_storage_container" "this" {
  for_each              = toset(var.containers)
  name                  = each.key
  storage_account_id    = azurerm_storage_account.adls.id
  container_access_type = var.container_access_type
}


# Private Endpoint for ADLS (Azure Data Lake Storage)
resource "azurerm_private_endpoint" "adls" {
  name                = "pe-adls-${var.project}-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  tags = var.default_tags

  private_service_connection {
    name                           = "adlsConnection"
    private_connection_resource_id = azurerm_storage_account.adls.id
    subresource_names              = var.pe_subresource_names # For ADLS Gen2
    is_manual_connection           = var.is_manual_connection
  }
}

resource "azurerm_monitor_diagnostic_setting" "adls" {
  name                       = "logs-adls-${var.project}-${var.environment}"
  target_resource_id         = "${azurerm_storage_account.adls.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_id

  dynamic "enabled_log" {
    for_each = var.adls_logs
    content {
      category = enabled_log.value
    }
  }

  #enabled_metric {
  # category = "Transaction"
  # }
}

# Assign Datalake permissions 
resource "azurerm_role_assignment" "adls_group_permissions" {
  for_each             = var.adls_rbac
  scope                = azurerm_storage_account.adls.id
  role_definition_name = each.value.role_definition_name
  principal_id         = data.azuread_group.adls_groups[each.key].object_id
}
