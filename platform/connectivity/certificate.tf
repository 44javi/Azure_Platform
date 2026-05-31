# P2S VPN certificate authentication — data sources for the existing centralized Key Vault.
#
# This file activates automatically when vpn_auth_types includes "Certificate".
# Before running `terraform apply`, populate the Key Vault secret with the
# base64-encoded public cert data of your root CA (no PEM header/footer lines).
#
# Required variables when Certificate auth is active:
#   mg_kv_name                   — name of the central management Key Vault
#   mg_kv_rg                     — resource group of that Key Vault
#   vpn_root_cert_kv_secret_name — secret name (default: "p2s-root-cert-data")

data "azurerm_key_vault" "vpn_cert" {
  count               = local.vpn_use_cert ? 1 : 0
  name                = var.mg_kv_name
  resource_group_name = var.mg_kv_rg

  provider = azurerm.management
}

data "azurerm_key_vault_secret" "p2s_cert" {
  count        = local.vpn_use_cert ? 1 : 0
  name         = var.vpn_root_cert_kv_secret_name
  key_vault_id = data.azurerm_key_vault.vpn_cert[0].id

  provider = azurerm.management
}
