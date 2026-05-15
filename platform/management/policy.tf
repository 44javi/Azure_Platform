resource "azurerm_management_group_policy_assignment" "change_tracking" {
  name                 = "change-tracking-ama"
  display_name         = "Enable ChangeTracking and Inventory for VMs"
  management_group_id  = azurerm_management_group.cyber_nimbus.id
  policy_definition_id = "/providers/Microsoft.Authorization/policySetDefinitions/92a36f05-ebc9-4bba-9128-b47ad2ea3354"
  location             = var.region

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    dcrResourceId = {
      value = azurerm_monitor_data_collection_rule.change_tracking.id
    }
    listOfApplicableLocations = {
      value = var.regions
    }
    bringYourOwnUserAssignedManagedIdentity = {
      value = false
    }
  })
}

# Roles required for the system-assigned identity to deploy AMA and DCR associations
resource "azurerm_role_assignment" "change_tracking_vm_contributor" {
  scope                = azurerm_management_group.cyber_nimbus.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_management_group_policy_assignment.change_tracking.identity[0].principal_id
}

resource "azurerm_role_assignment" "change_tracking_monitoring_contributor" {
  scope                = azurerm_management_group.cyber_nimbus.id
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_management_group_policy_assignment.change_tracking.identity[0].principal_id
}

resource "azurerm_role_assignment" "change_tracking_log_analytics_contributor" {
  scope                = azurerm_management_group.cyber_nimbus.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azurerm_management_group_policy_assignment.change_tracking.identity[0].principal_id
}

resource "azurerm_role_assignment" "change_tracking_contributor" {
  scope                = azurerm_management_group.cyber_nimbus.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_management_group_policy_assignment.change_tracking.identity[0].principal_id
}

resource "azurerm_role_assignment" "change_tracking_user_admin" {
  scope                = azurerm_management_group.cyber_nimbus.id
  role_definition_name = "User Access Administrator"
  principal_id         = azurerm_management_group_policy_assignment.change_tracking.identity[0].principal_id
}

resource "azurerm_management_group_policy_remediation" "change_tracking" {
  for_each = var.policies

  name                             = "remediate-change-tracking-${each.key}"
  management_group_id              = azurerm_management_group.cyber_nimbus.id
  policy_assignment_id             = azurerm_management_group_policy_assignment.change_tracking.id
  policy_definition_reference_id   = each.value

  depends_on = [
    azurerm_role_assignment.change_tracking_vm_contributor,
    azurerm_role_assignment.change_tracking_monitoring_contributor,
    azurerm_role_assignment.change_tracking_log_analytics_contributor,
    azurerm_role_assignment.change_tracking_contributor,
    azurerm_role_assignment.change_tracking_user_admin,
  ]
}