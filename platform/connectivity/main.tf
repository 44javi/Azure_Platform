resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.region
}

module "network_connectivity" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  vnet_address_space  = var.vnet_address_space
  project             = var.project
  environment         = var.environment
  region              = var.region
  subnets             = var.subnets
  default_tags        = local.default_tags
  private_dns_zones   = var.private_dns_zones
}

# Point the hub VNet at the DNS Private Resolver inbound endpoint so all VNet
# resources and VPN clients resolve private endpoint FQDNs via private DNS zones.
# Only created when enable_dns_resolver = true (resolver must exist first).
resource "azurerm_virtual_network_dns_servers" "hub" {
  count              = var.enable_dns_resolver ? 1 : 0
  virtual_network_id = module.network_connectivity.vnet_id
  dns_servers        = [azurerm_private_dns_resolver_inbound_endpoint.hub[0].ip_configurations[0].private_ip_address]
}
