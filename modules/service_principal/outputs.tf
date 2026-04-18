# Outputs
output "service_principal_object_id" {
  description = "Object ID of the service principal"
  value       = azuread_service_principal.this.object_id
}

output "certificate_name" {
  description = "Name of the certificate in Key Vault (null when credential_type = 'secret')"
  value       = var.credential_type == "certificate" ? azurerm_key_vault_certificate.sp_cert[0].name : null
}

output "key_vault_certificate_id" {
  description = "Key Vault certificate ID (null when credential_type = 'secret')"
  value       = var.credential_type == "certificate" ? azurerm_key_vault_certificate.sp_cert[0].id : null
}

output "certificate_secret_id" {
  description = "Key Vault secret ID for the certificate (null when credential_type = 'secret')"
  value       = var.credential_type == "certificate" ? azurerm_key_vault_certificate.sp_cert[0].secret_id : null
  sensitive   = true
}

output "client_secret_name" {
  description = "Key Vault secret name for the client secret (null when credential_type = 'certificate')"
  value       = var.credential_type == "secret" ? azurerm_key_vault_secret.sp_secret[0].name : null
}

output "client_secret_id" {
  description = "Key Vault secret ID for the client secret (null when credential_type = 'certificate')"
  value       = var.credential_type == "secret" ? azurerm_key_vault_secret.sp_secret[0].id : null
  sensitive   = true
}
