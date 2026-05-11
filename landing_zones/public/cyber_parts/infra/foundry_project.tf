############################################
# Azure AI Foundry Hub
# Required parent for the Foundry project.
# Connects to existing AI Services, Storage, and Key Vault.
############################################
resource "azurerm_ai_foundry" "hub" {
  name                    = "hub-${var.project}-${var.environment}"
  location                = azurerm_resource_group.main.location
  resource_group_name     = azurerm_resource_group.main.name
  storage_account_id      = module.docs_storage.id
  key_vault_id            = data.azurerm_key_vault.this.id
  application_insights_id = azurerm_application_insights.this.id
  public_network_access   = "Disabled"
  tags                    = var.default_tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "foundry_hub" {
  provider            = azurerm.connectivity
  name                = "pe-hub-${var.project}-${var.environment}"
  resource_group_name = var.hub_vnet_resource_group_name
  location            = var.region
  subnet_id           = data.azurerm_subnet.foundry.id
  tags                = var.default_tags

  private_service_connection {
    name                           = "psc-hub-${var.project}-${var.environment}"
    private_connection_resource_id = azurerm_ai_foundry.hub.id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.aml_api.id,
      data.azurerm_private_dns_zone.aml_notebooks.id,
    ]
  }
}

############################################
# Azure AI Foundry Project
############################################
resource "azurerm_ai_foundry_project" "this" {
  name               = "proj-${var.project}-${var.environment}"
  location           = azurerm_ai_foundry.hub.location
  ai_services_hub_id = azurerm_ai_foundry.hub.id
  tags               = var.default_tags

  identity {
    type = "SystemAssigned"
  }
}

############################################
# RBAC — Hub system identity to backend services
############################################

# Hub → AI Services: create connections and deployments
resource "azurerm_role_assignment" "hub_to_openai" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services OpenAI Contributor"
  principal_id         = azurerm_ai_foundry.hub.identity[0].principal_id
}

# # Hub → Storage: read/write documents for indexing pipelines
# resource "azurerm_role_assignment" "hub_to_storage" {
#   scope                = module.docs_storage.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_ai_foundry.hub.identity[0].principal_id
# }

# Hub → Key Vault: read secrets referenced in connections
resource "azurerm_role_assignment" "hub_to_kv" {
  scope                = data.azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_ai_foundry.hub.identity[0].principal_id
}
