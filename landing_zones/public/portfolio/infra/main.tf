resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.region
}

# data "azurerm_log_analytics_workspace" "management" {
#   provider            = azurerm.management
#   name                = var.log_analytics_workspace_name
#   resource_group_name = var.log_analytics_resource_group
# }

module "ca_portfolio" {
  source              = "../../../../modules/compute/container_apps"
  resource_group_name = azurerm_resource_group.main.name
  region              = var.region
  project             = var.project
  environment         = var.environment
  default_tags        = local.default_tags

  #log_analytics_workspace_id = data.azurerm_log_analytics_workspace.management.id
  docker_usr           = var.docker_usr
  enable_custom_domain = var.enable_custom_domain
  custom_domain        = var.custom_domain
  custom_domain_www    = var.custom_domain_www
  container_image      = var.container_image
}
