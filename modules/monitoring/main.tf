data "azurerm_client_config" "current" {}

resource "azurerm_monitor_action_group" "alerts" {
  name                = "alerts-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  short_name          = var.action_group_short_name

  email_receiver {
    name          = "alerts"
    email_address = var.alert_email
  }
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "log${var.project}${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_retention_days

  daily_quota_gb             = var.log_daily_quota_gb
  internet_ingestion_enabled = var.internet_ingestion_enabled
  internet_query_enabled     = var.internet_query_enabled

  tags = var.default_tags
}

# Role assignment for current user
resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_log_analytics_workspace.this.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}
