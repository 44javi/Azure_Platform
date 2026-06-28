# output for data_resources module

output "id" {
  description = "The resource ID of the storage account"
  value       = azurerm_storage_account.adls.id
}

output "name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.adls.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint (https://<account>.blob.core.windows.net/)"
  value       = azurerm_storage_account.adls.primary_blob_endpoint
}

# output "datalake_name" {
#   description = "The name of the Azure Data Lake Storage account"
#   value       = azurerm_storage_account.adls.name
# }

# output "datalake_id" {
#   description = "The resource ID of the Azure Data Lake Storage account"
#   value       = azurerm_storage_account.adls.id
# }

# output "datalake_endpoint" {
#   description = "The primary Blob service endpoint for the storage account"
#   value       = azurerm_storage_account.adls.primary_blob_endpoint
# }

# output "datalake_connection" {
#   description = "The primary connection string for the storage account"
#   value       = azurerm_storage_account.adls.primary_connection_string
#   sensitive   = true
# }

# output "private_endpoint_id" {
#   description = "The resource ID of the storage private endpoint"
#   value       = azurerm_private_endpoint.adls.id
# }

