# For Azure Backend set up

# Creates a Resource Group

resource "azurerm_resource_group" "state" {
  name     = "rg-state-${var.environment}"
  location = var.region

  tags = local.default_tags
}

# for tags
locals {
  default_tags = {
    environment = var.environment
    region      = var.region
    created_by  = "Terraform"
  }
}

# Random string for storage names
resource "random_string" "this" {
  length  = 1
  special = false
  upper   = false
  lower   = false
  numeric = true
}


data "azurerm_client_config" "current" {}

# Storage Blob Data Contributor - for state file operations
resource "azurerm_role_assignment" "current_user_blob" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Storage account for state
resource "azurerm_storage_account" "state" {
  name                = "st${var.project}state${var.environment}${random_string.this.result}"
  location            = var.region
  resource_group_name = azurerm_resource_group.state.name

  account_tier                      = var.account_tier
  account_kind                      = var.account_kind
  account_replication_type          = var.account_replication_type
  https_traffic_only_enabled        = var.https_traffic_only_enabled
  min_tls_version                   = var.min_tls_version
  shared_access_key_enabled         = var.shared_access_key_enabled
  default_to_oauth_authentication   = var.default_to_oauth_authentication
  infrastructure_encryption_enabled = var.infrastructure_encryption_enabled
  allow_nested_items_to_be_public   = var.allow_nested_items_to_be_public
  public_network_access_enabled     = var.public_network_access_enabled # false blocks access to containers on the portal




  blob_properties {
    versioning_enabled            = var.versioning_enabled
    change_feed_enabled           = var.change_feed_enabled
    change_feed_retention_in_days = var.change_feed_retention_in_days
    last_access_time_enabled      = var.last_access_time_enabled

    delete_retention_policy {
      days = var.st_retention_days
    }
    container_delete_retention_policy {
      days = var.st_retention_days
    }
  }
  sas_policy {
    expiration_period = var.sas_expiration_period
    expiration_action = var.sas_expiration_action
  }
}

# Create container in the storage account for state
resource "azurerm_storage_container" "this" {
  name                  = "${var.project}-state-${var.environment}"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = var.container_access_type
}
