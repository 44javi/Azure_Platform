# /modules/security/outputs.tf

output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.this.id
}

output "tenant_id" {
  value = data.azurerm_project_config.current.tenant_id
}



