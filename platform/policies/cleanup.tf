###############################################################################
# TTL: stamp a creation-date tag on every resource group
#
# cleanup.sh ages out resource groups by a creation-date tag. Resource groups
# have no native createdTime in ARM, so this Azure Policy stamps one at create
# time. A Modify policy evaluates at resource-write time.
#
# Effect: Modify. Adds the tag only when absent, so updates never reset it.
# Scope:  this subscription (var.subscription_id), where the lab runs.
#
# The assignment's system-assigned identity needs Tag Contributor to write the
# tag during remediation of existing resource groups. Tag Contributor can tag
# resource groups via the REST/policy path.
###############################################################################

locals {
  created_tag = "CreatedOnDate"

  # Built-in "Tag Contributor" role definition ID.
  tag_contributor_role_id = "/providers/Microsoft.Authorization/roleDefinitions/4a9ae827-6dc8-4573-8ac7-8239d42aa03f"
}

data "azurerm_subscription" "current" {} # 7f5cea79-d79d-4cc1-83f0-c62ac81814ce

resource "azurerm_policy_definition" "rg_created_date" {
  name         = "rg-created-date"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Stamp ${local.created_tag} tag on resource groups"
  description  = "Adds a ${local.created_tag} tag (utcNow()) to resource groups that lack it, so the lab TTL cleanup can age them out."

  metadata = jsonencode({
    category = "Tags"
  })

  parameters = jsonencode({
    tagName = {
      type = "String"
      metadata = {
        displayName = "Tag name"
        description = "Creation-date tag to stamp on resource groups."
      }
      defaultValue = local.created_tag
    }
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          field  = "[concat('tags[', parameters('tagName'), ']')]"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "modify"
      details = {
        roleDefinitionIds = [local.tag_contributor_role_id]
        operations = [
          {
            operation = "add"
            field     = "[concat('tags[', parameters('tagName'), ']')]"
            value     = "[utcNow()]"
          }
        ]
      }
    }
  })
}

resource "azurerm_subscription_policy_assignment" "rg_created_date" {
  name                 = "stamp-rg-created-date"
  display_name         = "Stamp ${local.created_tag} tag on resource groups"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = azurerm_policy_definition.rg_created_date.id
  location             = var.region

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    tagName = {
      value = local.created_tag
    }
  })
}

resource "azurerm_role_assignment" "rg_created_date_tag_contributor" {
  scope              = data.azurerm_subscription.current.id
  role_definition_id = local.tag_contributor_role_id
  principal_id       = azurerm_subscription_policy_assignment.rg_created_date.identity[0].principal_id
}

# Backfills the tag onto resource groups that already exist when the policy is
# assigned (including the Terraform-managed RGs created in this same config).
resource "azurerm_subscription_policy_remediation" "rg_created_date" {
  name                 = "remediate-rg-created-date"
  subscription_id      = data.azurerm_subscription.current.id
  policy_assignment_id = azurerm_subscription_policy_assignment.rg_created_date.id

  depends_on = [azurerm_role_assignment.rg_created_date_tag_contributor]
}
