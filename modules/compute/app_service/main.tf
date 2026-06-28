############################################
# App Service Plan (Windows)
############################################
resource "azurerm_service_plan" "this" {
  name                = "asp-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  os_type             = "Windows"
  sku_name            = var.app_service_plan_sku
  tags                = var.default_tags
}

############################################
# Windows Web App — chatbot frontend/api
# - System-assigned managed identity
# - VNet integration outbound to reach private endpoints
# - Public access disabled, ingress only via Front Door private link
############################################
resource "azurerm_windows_web_app" "this" {
  name                          = "app-${var.project}-${var.environment}"
  resource_group_name           = var.resource_group_name
  location                      = var.region
  service_plan_id               = azurerm_service_plan.this.id
  https_only                    = true
  public_network_access_enabled = false
  virtual_network_subnet_id     = var.appservice_integration_subnet_id
  tags                          = var.default_tags

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on              = true
    ftps_state             = "Disabled"
    minimum_tls_version    = "1.2"
    vnet_route_all_enabled = true # route ALL outbound through VNet

    application_stack {
      current_stack  = "node"
      node_version   = "~20"
    }

    ip_restriction_default_action = "Deny"
    # Front Door reaches us via private endpoint, which bypasses access restrictions.
  }

  app_settings = {
    # Wire the app to backend services. With system-assigned identity,
    # DefaultAzureCredential picks it up automatically — no AZURE_CLIENT_ID needed.
    AZURE_OPENAI_ENDPOINT                 = azurerm_cognitive_account.foundry.endpoint
    AZURE_OPENAI_CHAT_DEPLOYMENT          = "chat"
    AZURE_OPENAI_EMBED_DEPLOYMENT         = "embed"
    AZURE_SEARCH_ENDPOINT                 = "https://${azurerm_search_service.this.name}.search.windows.net"
    AZURE_SEARCH_INDEX_NAME               = "documents"
    AZURE_STORAGE_ACCOUNT                 = azurerm_storage_account.docs.name
    AZURE_STORAGE_CONTAINER               = azurerm_storage_container.documents.name
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.this.connection_string
    WEBSITE_RUN_FROM_PACKAGE              = "1"
  }

  logs {
    application_logs {
      file_system_level = "Information"
    }
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }
}

############################################
# Inbound Private Endpoint for the Web App
# Front Door Premium connects to this via Private Link
############################################
resource "azurerm_private_endpoint" "app_service" {
  name                = "pe-app-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  subnet_id           = var.private_endpoints_subnet_id
  tags                = var.default_tags

  private_service_connection {
    name                           = "psc-app-${var.project}-${var.environment}"
    private_connection_resource_id = azurerm_windows_web_app.this.id
    subresource_names              = ["sites"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.private_dns_zone_ids.app_service]
  }
}
