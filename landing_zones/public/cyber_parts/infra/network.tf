# --------------------------------------------------------------------------
# Hub VNet — read from connectivity subscription
# --------------------------------------------------------------------------
data "azurerm_virtual_network" "hub" {
  provider            = azurerm.connectivity
  name                = var.hub_vnet_name
  resource_group_name = var.hub_vnet_resource_group_name
}

# --------------------------------------------------------------------------
# Foundry spoke VNet — 10.80.0.0/21
# Peered to the connectivity hub; subnets and private endpoints live here.
# --------------------------------------------------------------------------
resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-${var.project}-${var.environment}"
  address_space       = [var.spoke_vnet_address_space]
  location            = var.region
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.default_tags
}

locals {
  # All subnets get an NSG — every subnet must be covered. Add rules per subnet in tfvars.
  # The dynamic security_rule block handles an empty nsg_rules list with no rules created.
  subnets_with_nsg = var.subnets

  # NAT Gateway is shared across all spoke subnets that opt in with attach_nat_gateway = true.
  # Only created when at least one subnet needs it.
  create_nat_gateway = anytrue([for s in var.subnets : s.attach_nat_gateway])
  subnets_with_nat   = { for k, v in var.subnets : k => v if v.attach_nat_gateway }

  hub_dns_zones = {
    services_ai = "privatelink.services.ai.azure.com"
    openai      = "privatelink.openai.azure.com"
    cognitive   = "privatelink.cognitiveservices.azure.com"
    search      = "privatelink.search.windows.net"
    blob        = "privatelink.blob.core.windows.net"
    key_vault   = "privatelink.vaultcore.azure.net"
    app_service = "privatelink.azurewebsites.net"
    # cosmos_db = "privatelink.documents.azure.com"  # Cosmos DB
  }
}

# Subnets — one per entry in var.subnets
resource "azurerm_subnet" "spoke" {
  for_each = var.subnets

  name                              = coalesce(each.value.name_override, "snet-${each.key}-${var.project}-${var.environment}")
  resource_group_name               = azurerm_resource_group.main.name
  virtual_network_name              = azurerm_virtual_network.spoke.name
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
resource "azurerm_network_security_group" "spoke" {
  for_each = local.subnets_with_nsg

  name                = "nsg-${each.key}-${var.project}-${var.environment}"
  location            = var.region
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.default_tags

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

resource "azurerm_subnet_network_security_group_association" "spoke" {
  for_each = local.subnets_with_nsg

  subnet_id                 = azurerm_subnet.spoke[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke[each.key].id
}

# --------------------------------------------------------------------------
# NAT Gateway — shared across spoke subnets that set attach_nat_gateway = true.
# Only provisioned when at least one subnet opts in.
# Replace with hub Azure Firewall + UDRs when centralized egress is needed.
# --------------------------------------------------------------------------
resource "azurerm_public_ip" "nat_gateway" {
  count               = local.create_nat_gateway ? 1 : 0
  name                = "pip-ng-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.default_tags
}

resource "azurerm_nat_gateway" "spoke" {
  count               = local.create_nat_gateway ? 1 : 0
  name                = "ng-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  tags                = local.default_tags
}

resource "azurerm_nat_gateway_public_ip_association" "spoke" {
  count                = local.create_nat_gateway ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.spoke[0].id
  public_ip_address_id = azurerm_public_ip.nat_gateway[0].id
}

resource "azurerm_subnet_nat_gateway_association" "spoke" {
  for_each = local.subnets_with_nat

  subnet_id      = azurerm_subnet.spoke[each.key].id
  nat_gateway_id = azurerm_nat_gateway.spoke[0].id
}

# --------------------------------------------------------------------------
# VNet Peering — hub and spoke
# Both directions must be configured for traffic to flow.
# --------------------------------------------------------------------------
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                         = "peer-to-hub"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.spoke.name
  remote_virtual_network_id    = data.azurerm_virtual_network.hub.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # Must be true when the hub has a VPN or ExpressRoute gateway (var.enable_vpn = true)
  use_remote_gateways          = var.enable_vpn
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  provider                     = azurerm.connectivity
  name                         = "peer-to-${var.project}-${var.environment}"
  resource_group_name          = var.hub_vnet_resource_group_name
  virtual_network_name         = data.azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  # Must be true when the hub has a VPN or ExpressRoute gateway (var.enable_vpn = true)
  allow_gateway_transit        = var.enable_vpn
}

# --------------------------------------------------------------------------
# Private DNS zone VNet links — hub zones → spoke VNet
# Required so resources in the spoke resolve private endpoint FQDNs via the
# hub-managed zones. Add a new entry to hub_dns_zones when a new zone is
# added to connectivity/env/prod.tfvars.
# --------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "hub_to_spoke" {
  for_each              = local.hub_dns_zones
  provider              = azurerm.connectivity
  name                  = "link-${var.project}-${var.environment}-${replace(each.value, ".", "-")}"
  resource_group_name   = var.hub_vnet_resource_group_name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.spoke.id
  registration_enabled  = false
  tags                  = local.default_tags
}

# --------------------------------------------------------------------------
# Private DNS zones — read from connectivity hub.
# Add a new data source here when a new zone is added to connectivity tfvars.
# --------------------------------------------------------------------------
data "azurerm_private_dns_zone" "services_ai" {
  provider            = azurerm.connectivity
  name                = "privatelink.services.ai.azure.com"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "cognitive" {
  provider            = azurerm.connectivity
  name                = "privatelink.cognitiveservices.azure.com"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "openai" {
  provider            = azurerm.connectivity
  name                = "privatelink.openai.azure.com"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "search" {
  provider            = azurerm.connectivity
  name                = "privatelink.search.windows.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "blob" {
  provider            = azurerm.connectivity
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "key_vault" {
  provider            = azurerm.connectivity
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

data "azurerm_private_dns_zone" "app_service" {
  provider            = azurerm.connectivity
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.hub_vnet_resource_group_name
}

# --------------------------------------------------------------------------
# Log Analytics Workspace — managed centrally in the management subscription
# --------------------------------------------------------------------------
data "azurerm_log_analytics_workspace" "this" {
  provider            = azurerm.management
  name                = var.law_name
  resource_group_name = var.law_resource_group_name
}
