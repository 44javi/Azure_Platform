# Network module

data "azurerm_client_config" "current" {}

locals {
  # Only create NSGs for subnets that have at least one rule defined
  subnets_with_nsg = { for k, v in var.subnets : k => v if length(v.nsg_rules) > 0 }

  # Only associate NAT gateway with subnets that opt in
  subnets_with_nat = { for k, v in var.subnets : k => v if v.attach_nat_gateway }
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project}-${var.environment}"
  address_space       = var.vnet_address_space
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.default_tags
}

# Subnets — one per entry in var.subnets
resource "azurerm_subnet" "subnets" {
  for_each = var.subnets

  # Use name_override when a fixed name is required (e.g. "AzureBastionSubnet")
  name                              = coalesce(each.value.name_override, "snet-${each.key}-${var.project}-${var.environment}")
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = [each.value.address_prefix]
  default_outbound_access_enabled   = !each.value.disable_default_outbound
  private_endpoint_network_policies = each.value.private_endpoint_network_policies

  dynamic "delegation" {
    for_each = each.value.delegation != null ? [each.value.delegation] : []
    content {
      name = delegation.value.service_name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

# NSGs — only created for subnets that declare nsg_rules
resource "azurerm_network_security_group" "subnets" {
  for_each = local.subnets_with_nsg

  name                = "nsg-${each.key}-${var.project}-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.default_tags

  dynamic "security_rule" {
    for_each = each.value.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      source_address_prefixes    = security_rule.value.source_address_prefixes
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}

# NSG associations
resource "azurerm_subnet_network_security_group_association" "subnets" {
  for_each = local.subnets_with_nsg

  subnet_id                 = azurerm_subnet.subnets[each.key].id
  network_security_group_id = azurerm_network_security_group.subnets[each.key].id
}

# NAT Gateway
resource "azurerm_nat_gateway" "this" {
  name                = "ng-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region

  tags = var.default_tags
}

# Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway" {
  name                = "ng-ip-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.default_tags
}

# NAT Gateway — Public IP association
resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

# NAT Gateway — Subnet associations (only for subnets with attach_nat_gateway = true)
resource "azurerm_subnet_nat_gateway_association" "subnets" {
  for_each = local.subnets_with_nat

  subnet_id      = azurerm_subnet.subnets[each.key].id
  nat_gateway_id = azurerm_nat_gateway.this.id

  depends_on = [azurerm_nat_gateway.this]
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
