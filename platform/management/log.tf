# # Create a Resource Group
# resource "azurerm_resource_group" "main" {
#   name     = "rg-${var.project}-${var.environment}"
#   location = var.region
# }

# # for tags
# locals {
#   default_tags = {
#     owner       = var.owner
#     environment = var.environment
#     project      = var.project
#     region      = var.region
#     created_by  = "Terraform"
#   }
# }

# resource "azurerm_monitor_action_group" "alerts" {
#   name                = "alerts-${var.project}-${var.environment}"
#   resource_group_name = azurerm_resource_group.main.name
#   short_name          = "alerts"

#   email_receiver {
#     name          = "alerts"
#     email_address = var.alert_email
#   }
# }

# resource "azurerm_log_analytics_workspace" "this" {
#   name                = "log-${var.project}-${var.environment}"
#   location            = var.region
#   resource_group_name = azurerm_resource_group.main.name
#   sku                 = "PerGB2018"   # SKUs: Free, PerGB2018, Standalone, CapacityReservation
#   retention_in_days   = 30            # Retention period for logs (30-730 days)

#   daily_quota_gb             = 1 # -1 for unlimited
#   internet_ingestion_enabled = true
#   internet_query_enabled     = true

#   tags = local.default_tags
# }

# # Role assignment for current user
# resource "azurerm_role_assignment" "admin" {
#   scope                = azurerm_log_analytics_workspace.this.id
#   role_definition_name = "Log Analytics Reader"  
#   principal_id         = data.azurerm_project_config.current.object_id
# }
