# =============================================================================
# DATABRICKS ACCOUNT-LEVEL NETWORK POLICY
# =============================================================================
# Egress rules are sourced from dbx_network.yml, keyed by var.environment.
# The security / network team can modify that file without touching Terraform.
# Enforcement is set to DRY_RUN across all products until ready to enforce
# (set enforcement_mode to "ENFORCED" when ready).

locals {
  dbx_network = yamldecode(file("${path.module}/dbx_network.yml"))[var.environment]
}

# Binds the network policy to one or more workspaces.
# workspace_id is the numeric Databricks workspace ID — find it with:
#   terraform state show module.dbx_workspace.azurerm_databricks_workspace.this | grep workspace_id
resource "databricks_workspace_network_option" "this" {
  provider          = databricks.account
  for_each          = { for id in local.dbx_network.workspace_ids : tostring(id) => id }
  workspace_id      = each.value
  network_policy_id = databricks_account_network_policy.this.network_policy_id
}

resource "databricks_account_network_policy" "this" {
  provider          = databricks.account
  account_id        = var.account_id
  network_policy_id = "netpol-${var.project}-${var.environment}"

  egress = {
    network_access = {
      restriction_mode = "RESTRICTED_ACCESS"

      allowed_internet_destinations = [
        for dest in local.dbx_network.egress_destinations : {
          destination               = dest
          internet_destination_type = "DNS_NAME"
        }
      ]

      allowed_storage_destinations = [
        for dest in local.dbx_network.storage_destinations : {
          azure_storage_account    = dest.storage_account
          azure_storage_service    = dest.storage_service
          storage_destination_type = "AZURE_STORAGE"
        }
      ]

      policy_enforcement = {
        enforcement_mode = "ENFORCED"
      }
    }
  }

  # ingress is defined in variables.tf but not yet in the provider schema (v1.112.0).
  # Uncomment once databricks/databricks provider releases ingress support.
  #
  # ingress = {
  #   public_access = {
  #     restriction_mode = "RESTRICTED_ACCESS"
  #
  #     allow_rules = [
  #       for rule in var.network_policy_ingress_allow_rules : {
  #         label = rule.label
  #         origin = rule.all_ip_ranges ? { all_ip_ranges = true } : {
  #           included_ip_ranges = { ip_ranges = rule.ip_ranges }
  #         }
  #         authentication = rule.identity_type != null ? {
  #           identity_type = rule.identity_type
  #         } : null
  #         destination = { all_destinations = rule.all_destinations }
  #       }
  #     ]
  #
  #     deny_rules = [
  #       for rule in var.network_policy_ingress_deny_rules : {
  #         label = rule.label
  #         origin = rule.all_ip_ranges ? { all_ip_ranges = true } : {
  #           included_ip_ranges = { ip_ranges = rule.ip_ranges }
  #         }
  #         authentication = rule.identity_type != null ? {
  #           identity_type = rule.identity_type
  #         } : null
  #         destination = { all_destinations = rule.all_destinations }
  #       }
  #     ]
  #   }
  # }
}
