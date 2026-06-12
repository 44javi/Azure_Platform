############################################################################
# Standard Agent Setup — BYO Cosmos DB + connections + RBAC + capability hosts
#
# Closes the gap that left capabilityHosts == []: the agent runtime had a
# delegated subnet but no capability host binding it to the VNet, so it never
# used snet-agentsegress and couldn't reach private Search.
#
# Required order (enforced via depends_on + a propagation wait):
#   1. Cosmos DB (private, keyless)
#   2. Three project connections: Search (exists), Storage, Cosmos
#   3. Project MI control-plane roles (Cosmos DB Operator, Storage Account
#      Contributor) — needed for caphost CREATION
#   4. Project MI data-plane roles (Search Index Data Reader, Storage Blob
#      Data Contributor, Cosmos DB Built-in Data Contributor) — needed for RUN
#   5. RBAC propagation wait
#   6. Account capability host (empty properties)
#   7. Project capability host (references the 3 connection names)
#
# Providers required: azurerm, azapi. Add azapi to required_providers if absent.
############################################################################

locals {
  project_mi_principal_id = azurerm_cognitive_account_project.this.identity[0].principal_id
  # Connection names as they must be referenced by the project capability host.
  search_connection_name  = "srchcyberpartsprodqfqf5f" # existing CognitiveSearch connection
  storage_connection_name = "conn-docs-storage"
  cosmos_connection_name  = "conn-cosmos-threads"
}

############################################
# Cosmos DB for NoSQL — thread storage (private, keyless)
############################################

resource "azurerm_cosmosdb_account" "threads" {
  name                          = "cosmos-${var.project}-${var.environment}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = var.region
  offer_type                    = "Standard"
  kind                          = "GlobalDocumentDB"
  public_network_access_enabled = false
  local_authentication_disabled = true # AAD/keyless only, matches the rest of the stack
  tags                          = var.default_tags

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = var.region
    failover_priority = 0
  }
}

resource "azurerm_private_endpoint" "cosmos" {
  name                = "pe-cosmos-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  subnet_id           = azurerm_subnet.spoke["privateendpoints"].id
  tags                = var.default_tags

  private_service_connection {
    name                           = "psc-cosmos-${var.project}-${var.environment}"
    private_connection_resource_id = azurerm_cosmosdb_account.threads.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "cosmos-dns"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.cosmos.id] # add this data source (privatelink.documents.azure.com)
  }
}

############################################
# Project connections — Storage + Cosmos
# (Search connection already exists: srchcnpartslabsetxhh)
# No azurerm resource exists for project connections; use azapi.
############################################

resource "azapi_resource" "conn_storage" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = local.storage_connection_name
  parent_id = azurerm_cognitive_account_project.this.id

  body = {
    properties = {
      category      = "AzureStorageAccount"
      target        = module.docs_storage.primary_blob_endpoint # https://<acct>.blob.core.windows.net/
      authType      = "AAD"
      isSharedToAll = false
      metadata = {
        ApiType    = "Azure"
        ResourceId = module.docs_storage.id
        location   = var.region
      }
    }
  }
  schema_validation_enabled = false
}

resource "azapi_resource" "conn_cosmos" {
  type      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-06-01"
  name      = local.cosmos_connection_name
  parent_id = azurerm_cognitive_account_project.this.id

  body = {
    properties = {
      category      = "CosmosDB"
      target        = azurerm_cosmosdb_account.threads.endpoint # https://<acct>.documents.azure.com:443/
      authType      = "AAD"
      isSharedToAll = false
      metadata = {
        ApiType    = "Azure"
        ResourceId = azurerm_cosmosdb_account.threads.id
        location   = var.region
      }
    }
  }
  schema_validation_enabled = false
}

############################################
# RBAC — CONTROL PLANE (required for capability host CREATION)
############################################

resource "azurerm_role_assignment" "proj_cosmos_operator" {
  scope                = azurerm_cosmosdb_account.threads.id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = local.project_mi_principal_id
}

resource "azurerm_role_assignment" "proj_storage_contributor" {
  scope                = module.docs_storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = local.project_mi_principal_id
}

############################################
# RBAC — DATA PLANE (required for agent RUNTIME)
############################################

# Search: query the index (this is the role gap from your earlier RBAC file)
resource "azurerm_role_assignment" "proj_search_reader" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = local.project_mi_principal_id
}

# Storage: read/write agent files + artifacts
resource "azurerm_role_assignment" "proj_storage_blob" {
  scope                = module.docs_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.project_mi_principal_id
}

# Cosmos data-plane: this is the SQL role assignment (NOT an azurerm_role_assignment).
# 00000000-0000-0000-0000-000000000002 = built-in "Cosmos DB Built-in Data Contributor".
# Scope at the account id covers all databases/containers.
resource "azurerm_cosmosdb_sql_role_assignment" "proj_cosmos_data" {
  resource_group_name = azurerm_resource_group.main.name
  account_name        = azurerm_cosmosdb_account.threads.name
  role_definition_id  = "${azurerm_cosmosdb_account.threads.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = local.project_mi_principal_id
  scope               = azurerm_cosmosdb_account.threads.id
}

############################################
# RBAC propagation wait — caphost creation fails if roles aren't live yet
############################################

# resource "time_sleep" "wait_rbac" {
#   depends_on = [
#     azurerm_role_assignment.proj_cosmos_operator,
#     azurerm_role_assignment.proj_storage_contributor,
#     azurerm_role_assignment.proj_search_reader,
#     azurerm_role_assignment.proj_storage_blob,
#     azurerm_cosmosdb_sql_role_assignment.proj_cosmos_data,
#   ]
#   create_duration = "180s"
# }

############################################
# Capability hosts — ACCOUNT first (empty), then PROJECT
############################################

# resource "azapi_resource" "account_capability_host" {
#   type      = "Microsoft.CognitiveServices/accounts/capabilityHosts@2025-06-01"
#   name      = "caphost-acct"
#   parent_id = azurerm_cognitive_account.foundry.id
#   timeouts {
#     create = "90m"
#     delete = "60m"
#   }

#   body = {
#     properties = {
#       capabilityHostKind = "Agents"
#       customerSubnet     = azurerm_subnet.spoke["agentsegress"].id
#     }
#   }
#   schema_validation_enabled = false

#   #   depends_on = [time_sleep.wait_rbac]
# }

resource "azapi_resource" "project_capability_host" {
  type      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-06-01"
  name      = "caphost-proj"
  parent_id = azurerm_cognitive_account_project.this.id

  body = {
    properties = {
      capabilityHostKind       = "Agents"
      vectorStoreConnections   = [local.search_connection_name]
      storageConnections       = [local.storage_connection_name]
      threadStorageConnections = [local.cosmos_connection_name]
    }
  }
  schema_validation_enabled = false

  timeouts {
    create = "90m"
    delete = "60m"
  }

  depends_on = [
    azapi_resource.conn_storage,
    azapi_resource.conn_cosmos,
  ]
}