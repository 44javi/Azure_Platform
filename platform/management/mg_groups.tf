# Root module management_groups
data "azurerm_client_config" "current" {}

# Create Management Groups
resource "azurerm_management_group" "cyber_nimbus" {
  display_name               = "Cybernetic Nimbus"
  parent_management_group_id = var.root_management_group_id
}

# Create Management Groups
resource "azurerm_management_group" "sandbox" {
  display_name               = "Sandbox"
  parent_management_group_id = azurerm_management_group.cyber_nimbus.id
}

resource "azurerm_management_group" "legacy" {
  display_name               = "Legacy"
  parent_management_group_id = azurerm_management_group.cyber_nimbus.id
}

# Create Management Groups
resource "azurerm_management_group" "platform" {
  display_name               = "Platform"
  parent_management_group_id = azurerm_management_group.cyber_nimbus.id
}

# Create Management Groups
resource "azurerm_management_group" "Management" {
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

# Create Management Groups
resource "azurerm_management_group" "landing_zones" {
  display_name               = "Landing Zones"
  parent_management_group_id = azurerm_management_group.cyber_nimbus.id
}

resource "azurerm_management_group" "public" {
  display_name               = "Public"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "private" {
  display_name               = "Private"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}
