output "resource_group_name" {
  description = "Name of the resource group holding the Terraform state storage account"
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Name of the storage account used for Terraform state"
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Name of the blob container used for Terraform state"
  value       = azurerm_storage_container.this.name
}
