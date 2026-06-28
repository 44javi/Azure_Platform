# Outputs
output "service_principal_object_id" {
  description = "Object ID of the service principal"
  value       = azuread_service_principal.this.object_id
}

output "application_client_id" {
  description = "Application client ID. Use this as ARM_CLIENT_ID for GitLab OIDC authentication."
  value       = azuread_application.this.client_id
}

output "application_object_id" {
  description = "Object ID of the Azure AD application registration"
  value       = azuread_application.this.object_id
}

output "tenant_id" {
  description = "Tenant ID. Use this as ARM_TENANT_ID for GitLab OIDC authentication."
  value       = data.azurerm_client_config.current.tenant_id
}

output "certificate_name" {
  description = "Name of the certificate in Key Vault (null unless credential_type = 'certificate')"
  value       = var.credential_type == "certificate" ? azurerm_key_vault_certificate.sp_cert[0].name : null
}

output "key_vault_certificate_id" {
  description = "Key Vault certificate ID (null unless credential_type = 'certificate')"
  value       = var.credential_type == "certificate" ? azurerm_key_vault_certificate.sp_cert[0].id : null
}

output "certificate_secret_id" {
  description = "Key Vault secret ID for the certificate (null unless credential_type = 'certificate')"
  value       = var.credential_type == "certificate" ? azurerm_key_vault_certificate.sp_cert[0].secret_id : null
  sensitive   = true
}

output "client_secret_name" {
  description = "Key Vault secret name for the client secret (null unless credential_type = 'secret')"
  value       = var.credential_type == "secret" ? azurerm_key_vault_secret.sp_secret[0].name : null
}

output "client_secret_id" {
  description = "Key Vault secret ID for the client secret (null unless credential_type = 'secret')"
  value       = var.credential_type == "secret" ? azurerm_key_vault_secret.sp_secret[0].id : null
  sensitive   = true
}

output "federated_identity_credential_ids" {
  description = "Map of federated identity credential resource IDs (empty unless credential_type = 'federated')"
  value       = { for key, credential in azuread_application_federated_identity_credential.this : key => credential.id }
}

output "federated_identity_credential_credential_ids" {
  description = "Map of federated identity credential UUIDs (empty unless credential_type = 'federated')"
  value       = { for key, credential in azuread_application_federated_identity_credential.this : key => credential.credential_id }
}
