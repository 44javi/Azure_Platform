resource "azurerm_role_assignment" "org_vm_admins" {
  scope                = azurerm_management_group.cyber_nimbus.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = azuread_group.org_vm_admins.object_id
}

resource "azurerm_role_assignment" "platform_vm_users" {
  scope                = azurerm_management_group.platform.id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = azuread_group.platform_vm_users.object_id
}