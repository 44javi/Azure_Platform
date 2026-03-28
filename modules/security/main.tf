# /modules/security/main.tf

# Get current Azure config
data "azurerm_client_config" "current" {}

data "azuread_group" "kv_groups" {
  for_each     = var.kv_rbac
  display_name = each.value.group_name
}

# Random string for storage names
resource "random_string" "kv" {
  length  = 4
  special = false
  upper   = false
  lower   = false
  numeric = true
}

# Creates a Key Vault 
resource "azurerm_key_vault" "this" {
  name                       = "kv-${var.project}-${var.environment}-${random_string.kv.result}"
  resource_group_name        = var.resource_group_name
  location                   = var.region
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.kv_sku_name
  rbac_authorization_enabled = var.kv_rbac_authorization_enabled
  soft_delete_retention_days = var.kv_soft_delete_retention_days
  purge_protection_enabled   = var.kv_purge_protection_enabled

  lifecycle {
    ignore_changes = [tenant_id]
  }

  tags = var.default_tags
}

resource "azurerm_role_assignment" "kv_group_permissions" {
  for_each             = var.kv_rbac
  scope                = azurerm_key_vault.this.id
  role_definition_name = each.value.role_definition_name
  principal_id         = data.azuread_group.kv_groups[each.key].object_id
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id

  # lifecycle {
  #ignore_changes = [principal_id]
  # }
}

/*
# Key vault permission
resource "azurerm_role_assignment" "data_engineers_keyvault" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_group.data_engineers.object_id

  lifecycle {
    ignore_changes = [principal_id]
  }
}
*/
