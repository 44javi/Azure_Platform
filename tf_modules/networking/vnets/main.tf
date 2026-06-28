# Network module

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project}-${var.environment}"
  address_space       = var.vnet_address_space
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.default_tags
}

# Private DNS Zones — one per entry in var.private_dns_zones
resource "azurerm_private_dns_zone" "zones" {
  for_each            = toset(var.private_dns_zones)
  name                = each.key
  resource_group_name = var.resource_group_name
  tags                = var.default_tags
}

# VNet links — required for DNS resolution to work from within the VNet
resource "azurerm_private_dns_zone_virtual_network_link" "zones" {
  for_each              = toset(var.private_dns_zones)
  name                  = "link-${replace(each.key, ".", "-")}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zones[each.key].name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
  tags                  = var.default_tags
}