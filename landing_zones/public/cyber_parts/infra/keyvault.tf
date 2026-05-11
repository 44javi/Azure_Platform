############################################
# Key Vault — data source
############################################
data "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name

  provider = azurerm.management
}
