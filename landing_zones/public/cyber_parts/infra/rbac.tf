############################################
# RBAC — Web App's system-assigned identity to backend services
############################################

# App → Search: query the index
resource "azurerm_role_assignment" "app_to_search_index_reader" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = azurerm_windows_web_app.this.identity[0].principal_id
}

# App → Search: contribute (if app manages the index schema/uploads)
resource "azurerm_role_assignment" "app_to_search_contributor" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Service Contributor"
  principal_id         = azurerm_windows_web_app.this.identity[0].principal_id
}

# App → Foundry/OpenAI: invoke models
resource "azurerm_role_assignment" "app_to_openai" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_windows_web_app.this.identity[0].principal_id
}

# App → Storage: read documents
resource "azurerm_role_assignment" "app_to_storage_reader" {
  scope                = azurerm_storage_account.docs.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_windows_web_app.this.identity[0].principal_id
}

# App → Key Vault: read secrets (if/when you store any)
resource "azurerm_role_assignment" "app_to_kv_secrets_user" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_windows_web_app.this.identity[0].principal_id
}

############################################
# RBAC — AI Search system identity to backend services
# So the indexer can pull from Storage and call OpenAI for embeddings
############################################

# Search → Storage: read source documents
resource "azurerm_role_assignment" "search_to_storage_reader" {
  scope                = azurerm_storage_account.docs.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_search_service.this.identity[0].principal_id
}

# Search → Foundry: call embedding model from skillset
resource "azurerm_role_assignment" "search_to_openai" {
  scope                = azurerm_cognitive_account.foundry.id
  role_definition_name = "Cognitive Services OpenAI User"
  principal_id         = azurerm_search_service.this.identity[0].principal_id
}