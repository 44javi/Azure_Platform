
resource "random_password" "secrets" {
  for_each = var.secrets

  length           = each.value.length
  special          = each.value.special
  override_special = "!#%&*()-_=+[]<>:?"

  min_upper   = each.value.min_upper
  min_lower   = each.value.min_lower
  min_numeric = each.value.min_numeric
  min_special = each.value.special ? each.value.min_special : 0

  keepers = {
    rotation_key = each.value.rotation_key
  }
}

# Store generated secrets in Key Vault
resource "azurerm_key_vault_secret" "secrets" {
  for_each = var.secrets

  name            = "${var.project}-${var.environment}-${each.key}"
  value           = random_password.secrets[each.key].result
  key_vault_id    = var.key_vault_id
  expiration_date = each.value.expiration_date

  tags = var.default_tags
}
