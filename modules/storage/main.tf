# data_resources module

# Get Azure subscription details
data "azurerm_project_config" "current" {}

data "azuread_group" "adls_groups" {
  for_each     = var.adls_rbac
  display_name = each.value.group_name
}

# Random string for storage names
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}

# Data Lake Storage
resource "azurerm_storage_account" "adls" {
  name                            = "adls${random_string.this.result}"
  resource_group_name             = var.resource_group_name
  location                        = var.region
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  account_kind                    = "StorageV2"
  is_hns_enabled                  = "true"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = true #false blocks access to containers on the portal
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
  container_access_type = "private"
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
    subresource_names              = ["dfs"] # For ADLS Gen2
    is_manual_connection           = false
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
