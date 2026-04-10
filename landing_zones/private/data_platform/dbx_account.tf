# =============================================================================
# DATABRICKS ACCOUNT-LEVEL NETWORK POLICY
# =============================================================================
# Egress rules, restriction_mode, and enforcement_mode are sourced from dbx_network.yml. 

locals {
  dbx_network = yamldecode(file("${path.module}/dbx_network.yml"))

  # Flatten workspace_id → env pairs for the binding resource.
  dbx_workspace_bindings = {
    for pair in flatten([
      for env, cfg in local.dbx_network : [
        for id in cfg.workspace_ids : {
          key          = "${env}-${id}"
          env          = env
          workspace_id = id
        }
      ]
    ]) : pair.key => pair
  }
}

resource "databricks_account_network_policy" "this" {
  provider          = databricks.account
  for_each          = local.dbx_network
  account_id        = var.account_id
  network_policy_id = "${each.key}-network-policy"

  egress = {
    network_access = {
      restriction_mode = each.value.restriction_mode

      allowed_internet_destinations = [
        for dest in each.value.egress_destinations : {
          destination               = dest
          internet_destination_type = "DNS_NAME"
        }
      ]

      allowed_storage_destinations = [
        for dest in each.value.storage_destinations : {
          azure_storage_account    = dest.storage_account
          azure_storage_service    = dest.storage_service
          storage_destination_type = "AZURE_STORAGE"
        }
      ]

      policy_enforcement = {
        enforcement_mode = each.value.enforcement_mode
      }
    }
  }
}

# Binds the network policy to one or more workspaces.
resource "databricks_workspace_network_option" "this" {
  provider          = databricks.account
  for_each          = local.dbx_workspace_bindings
  workspace_id      = each.value.workspace_id
  network_policy_id = databricks_account_network_policy.this[each.value.env].network_policy_id
}
