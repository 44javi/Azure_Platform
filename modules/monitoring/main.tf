data "azurerm_project_config" "current" {}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "alerts-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = "alerts"

  email_receiver {
    name          = "alerts"
    email_address = var.alert_email
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log${var.project}${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018" # SKUs: Free, PerGB2018, Standalone, CapacityReservation
  retention_in_days   = 30          # Retention period for logs (30-730 days)

  daily_quota_gb             = 1 # -1 for unlimited
  internet_ingestion_enabled = true
  internet_query_enabled     = true

  tags = var.default_tags
}

# Role assignment for current user
resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_log_analytics_workspace.this.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = data.azurerm_project_config.current.object_id
}
