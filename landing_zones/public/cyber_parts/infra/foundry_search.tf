############################################
# Azure AI Foundry (Cognitive Services account, kind=AIServices)
############################################
resource "azurerm_cognitive_account" "foundry" {
  name                          = "foundry-${var.project}-${var.environment}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.region
  kind                          = "AIServices"
  sku_name                      = "S0"
  custom_subdomain_name         = "dns-foundry-${var.project}-${var.environment}"
  project_management_enabled    = true
  public_network_access_enabled = false
  local_auth_enabled            = false # AAD only
  tags                          = var.default_tags

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

############################################
# Azure AI Search — private, system-assigned identity
############################################
resource "azurerm_search_service" "this" {
  name                          = "srch-${var.project}-${var.environment}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.region
  sku                           = var.search_sku
  replica_count                 = 1
  partition_count               = 1
  public_network_access_enabled = false
  local_authentication_enabled  = false # disable API keys
  semantic_search_sku           = "standard"
  network_rule_bypass_option    = "AzureServices"
  tags                          = var.default_tags

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "search" {
  name                = "pe-srch-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  subnet_id           = azurerm_subnet.spoke["privateendpoints"].id
  tags                = var.default_tags

  private_service_connection {
    name                           = "psc-srch-${var.project}-${var.environment}"
    private_connection_resource_id = azurerm_search_service.this.id
    subresource_names              = ["searchService"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.search.id]
  }
}

# Shared private link: lets Search reach Storage privately for indexing
resource "azurerm_search_shared_private_link_service" "storage" {
  name               = "spl-st-${var.project}-${var.environment}"
  search_service_id  = azurerm_search_service.this.id
  subresource_name   = "blob"
  target_resource_id = module.docs_storage.id
  request_message    = "AI Search to Storage for indexer"
}
