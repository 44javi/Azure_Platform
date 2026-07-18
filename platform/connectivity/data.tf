# Data sources for the connectivity root module.

# Central Key Vault in the management subscription. Holds shared secrets:
# the jumpbox break-glass SSH key, the P2S VPN root CA cert, and whatever
# else connectivity needs from the platform.
data "azurerm_key_vault" "management" {
  name                = var.mg_kv_name
  resource_group_name = var.mg_kv_rg

  provider = azurerm.management
}

# # P2S VPN certificate authentication — only read when vpn_auth_types includes
# # "Certificate". Before running `terraform apply`, populate the secret with the
# # base64-encoded public cert data of your root CA (no PEM header/footer lines).
# data "azurerm_key_vault_secret" "p2s_cert" {
#   count        = local.vpn_use_cert ? 1 : 0
#   name         = var.vpn_root_cert_kv_secret_name
#   key_vault_id = data.azurerm_key_vault.management.id

#   provider = azurerm.management
# }
