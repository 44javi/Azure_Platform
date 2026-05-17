############################################
# Azure AI Foundry Project
# Child of the AI Services account — no Hub required.
############################################
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

