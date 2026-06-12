# ############################################
# # Azure AI Foundry (Cognitive Services account, kind=AIServices)
# ############################################
resource "azurerm_cognitive_account" "foundry" {
  name                          = "foundry-${var.project}-${var.environment}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.region
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = "cdn-foundry-${var.project}-${var.environment}"
  project_management_enabled    = true
  public_network_access_enabled = false
  local_auth_enabled            = false # AAD only
  tags                          = var.default_tags

  identity {
    type = "SystemAssigned"
  }

  # Injects the agent runtime into our VNet so it can resolve the private
  # endpoints for Search/Storage/Cosmos DB. Must be set at account creation —
  # azurerm/Azure don't support adding this to an existing account.
  network_injection {
    scenario  = "agent"
    subnet_id = azurerm_subnet.spoke["agentsegress"].id
  }

  # customer_managed_key {
  #   key_vault_key_id   = azurerm_key_vault_key.foundry_cmk.id
  #   identity_client_id = null # null = use system-assigned identity
  # }
}

###########################################
# Azure AI Foundry Project 
###########################################
resource "azurerm_cognitive_account_project" "this" {
  name                 = "proj-${var.project}-${var.environment}"
  cognitive_account_id = azurerm_cognitive_account.foundry.id
  location             = var.region
  display_name         = "${var.project} ${var.environment}"
  tags                 = var.default_tags

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_cognitive_deployment" "models" {
  for_each             = var.openai_model_deployments
  name                 = each.key
  cognitive_account_id = azurerm_cognitive_account.foundry.id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.sku_capacity
  }
}

resource "azurerm_private_endpoint" "foundry" {
  name                = "pe-foundry-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  subnet_id           = azurerm_subnet.spoke["privateendpoints"].id
  tags                = var.default_tags

  depends_on = [azurerm_cognitive_deployment.models]

  private_service_connection {
    name                           = "psc-foundry-${var.project}-${var.environment}"
    private_connection_resource_id = azurerm_cognitive_account.foundry.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "default"
    private_dns_zone_ids = [
      data.azurerm_private_dns_zone.services_ai.id,
      data.azurerm_private_dns_zone.cognitive.id,
      data.azurerm_private_dns_zone.openai.id,
    ]
  }
}

