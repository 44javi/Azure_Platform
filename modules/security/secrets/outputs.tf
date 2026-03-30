output "secret_ids" {
  description = "Versioned Key Vault URIs — pinned to the exact secret version at apply time. Use for Terraform-to-Terraform references where determinism matters."
  value       = { for k, s in azurerm_key_vault_secret.secrets : k => s.id }
}

output "secret_versionless_ids" {
  description = "Versionless Key Vault URIs — always resolve to the latest version at runtime. Use for Databricks, AKS CSI, App Service, and any consumer that fetches the secret at runtime."
  value       = { for k, s in azurerm_key_vault_secret.secrets : k => s.versionless_id }
}

output "secret_versions" {
  description = "Current version ID per secret. Use to track rotation state — version changes when rotation_key changes."
  value       = { for k, s in azurerm_key_vault_secret.secrets : k => s.version }
  sensitive   = true
}