# Create External Security Group
resource "azuread_group" "External_Users" {
  display_name     = "External_Users"
  security_enabled = true
  description      = "Group for guests to have access to Azure resources"
}

# Create metastore admin
resource "azuread_group" "dbx_metastore_admins" {
  display_name     = "DBX_Metastore_Admins"
  security_enabled = true
  description      = "Group for users and principals to have access to the metastore"
}

resource "azuread_group" "dbx_account_admins" {
  display_name     = "DBX_Account_Admins"
  security_enabled = true
  description      = "Group for users and principals to have access to the Databricks account console"
}

# Department groups with dynamic membership driven by the user.department attribute
resource "azuread_group" "department" {
  for_each         = var.department_groups
  display_name     = each.value.display_name
  security_enabled = true
  description      = coalesce(each.value.description, "Dynamic group for the ${each.value.department} department")
  types            = ["DynamicMembership"]

  dynamic_membership {
    enabled = true
    rule    = "user.department -eq \"${each.value.department}\""
  }
}

resource "azuread_group" "org_owners" {
  display_name     = "${var.org}_Owners"
  security_enabled = true
  description      = "Group for owner permissions at the org management group"
}

resource "azuread_group" "org_vm_admins" {
  display_name     = "${var.org}_VM_Admins"
  security_enabled = true
  description      = "Sudo login on platform VMs via Entra ID, assigned Virtual Machine Administrator Login at the Platform management group"
}

resource "azuread_group" "platform_vm_users" {
  display_name     = "Platform_VM_Users"
  security_enabled = true
  description      = "Non-sudo login on platform VMs via Entra ID, assigned Virtual Machine User Login at the Platform management group"
}