# --------------------------------------------------------------------------
# Hub VNet & subnets — read from connectivity subscription
# Private endpoints for all Foundry services land in the foundry subnet.
# App Service VNet integration uses a separate delegated subnet to avoid
# the delegation conflict with private endpoints.
# --------------------------------------------------------------------------
data "azurerm_virtual_network" "hub" {
  provider            = azurerm.connectivity
  name                = var.hub_vnet_name
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_subnet" "foundry" {
  provider             = azurerm.connectivity
  name                 = "snet-foundry-connectivity-prod"
  virtual_network_name = data.azurerm_virtual_network.hub.name
  resource_group_name  = var.hub_vnet_resource_group_name
}

# # Separate subnet delegated to Microsoft.Web/serverFarms for App Service VNet integration
# data "azurerm_subnet" "appservice_integration" {
#   provider             = azurerm.connectivity
#   name                 = var.appservice_integration_subnet_name
#   virtual_network_name = data.azurerm_virtual_network.hub.name
#   resource_group_name  = var.hub_vnet_resource_group_name
# }

# --------------------------------------------------------------------------
# Private DNS zones — managed centrally in the connectivity subscription.
# Add a new data source here when a new zone is added to connectivity tfvars.
# --------------------------------------------------------------------------
data "azurerm_private_dns_zone" "cognitive" {
  provider            = azurerm.connectivity
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "openai" {
  provider            = azurerm.connectivity
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "search" {
  provider            = azurerm.connectivity
  name                = "privatelink.search.windows.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "blob" {
  provider            = azurerm.connectivity
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "key_vault" {
  provider            = azurerm.connectivity
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "app_service" {
  provider            = azurerm.connectivity
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "aml_api" {
  provider            = azurerm.connectivity
  name                = "privatelink.api.azureml.ms"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "aml_notebooks" {
  provider            = azurerm.connectivity
  name                = "privatelink.notebooks.azure.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

# --------------------------------------------------------------------------
# Log Analytics Workspace — managed centrally in the management subscription
# --------------------------------------------------------------------------
data "azurerm_log_analytics_workspace" "this" {
  provider            = azurerm.management
  name                = var.law_name
  resource_group_name = var.law_resource_group_name
}
