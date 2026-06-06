############################################
# Key Vault — data source
############################################
data "azurerm_key_vault" "this" {
  name                = var.key_vault_name
  resource_group_name = var.key_vault_resource_group_name

  provider = azurerm.management
}

# ############################################
# # Key Vault Key for CMK
# ############################################
# resource "azurerm_key_vault_key" "foundry_cmk" {
#   name         = "foundry-cmk"
#   key_vault_id = data.azurerm_key_vault.this.id
#   key_type     = "RSA"
#   key_size     = 2048

#   key_opts = [
#     "unwrapKey",
#     "wrapKey",
#   ]

#   provider = azurerm.management
# }