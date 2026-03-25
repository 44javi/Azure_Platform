# /modules/automation/main.tf

# Get current Azure config
data "azurerm_subscription" "current" {}

resource "azurerm_automation_account" "this" {
  name                = "aa-${var.project}-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku_name            = "Basic"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "aa_vm_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azurerm_automation_account.this.identity[0].principal_id

  lifecycle {
    ignore_changes = [scope]
  }
}

# ================= RUNBOOK =================
resource "azurerm_automation_runbook" "manage_vms" {
  name                    = "rb-manage-vms"
  location                = var.region
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  runbook_type            = "PowerShell"
  log_verbose             = false
  log_progress            = false
  content                 = file("${path.module}/scripts/automation/manage-vmsv2.ps1")
}



# ================= SCHEDULES =================

# Schedule to stop VMs in PROD every weekday.
resource "azurerm_automation_schedule" "this" {
  for_each                = var.vm_schedules
  name                    = "${var.environment}-${each.key}"
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  frequency               = each.value.frequency
  timezone                = "America/Chicago"
  start_time              = each.value.start_time
  week_days               = each.value.week_days
  description             = each.value.description
  lifecycle {
    #ignore_changes = [start_time]
  }
}

# Link PROD schedule to runbook
resource "azurerm_automation_job_schedule" "links" {
  for_each                = var.vm_schedules
  resource_group_name     = var.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  schedule_name           = azurerm_automation_schedule.this[each.key].name
  runbook_name            = azurerm_automation_runbook.manage_vms.name

  parameters = {
    vmnames = each.value.vm_names
    action  = each.value.action
  }
}

