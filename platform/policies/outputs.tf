output "policy_definition_id" {
  description = "ID of the custom policy definition that stamps the creation-date tag."
  value       = azurerm_policy_definition.rg_created_date.id
}

output "policy_assignment_id" {
  description = "ID of the subscription-scoped policy assignment."
  value       = azurerm_subscription_policy_assignment.rg_created_date.id
}

output "policy_assignment_principal_id" {
  description = "Principal ID of the assignment's system-assigned identity (granted Tag Contributor)."
  value       = azurerm_subscription_policy_assignment.rg_created_date.identity[0].principal_id
}
