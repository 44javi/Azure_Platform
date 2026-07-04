resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project}-${var.environment}"
  location = var.region
}

# Hub virtual network plus its private DNS zones and VNet links.
module "hub_vnet" {
  source = "git::https://gitlab.com/cybernetic-nimbus-group/cloud/azure-platform.git//tf_modules/networking/vnets?ref=vnets-v1.0.0"

  resource_group_name = azurerm_resource_group.main.name
  resource_group_id   = azurerm_resource_group.main.id
  vnet_address_space  = var.vnet_address_space
  project             = var.project
  environment         = var.environment
  region              = var.region
  default_tags        = local.default_tags
  private_dns_zones   = var.private_dns_zones
}

# Subnets in the hub VNet, with optional per-subnet NSGs and NAT gateway.
module "hub_subnets" {
  source = "git::https://gitlab.com/cybernetic-nimbus-group/cloud/azure-platform.git//tf_modules/networking/subnets?ref=subnets-v1.0.0"

  resource_group_name  = azurerm_resource_group.main.name
  resource_group_id    = azurerm_resource_group.main.id
  virtual_network_name = module.hub_vnet.vnet_name
  project              = var.project
  environment          = var.environment
  region               = var.region
  subnets              = var.subnets
  default_tags         = local.default_tags
}

# Point the hub VNet at the DNS Private Resolver inbound endpoint so all VNet
# resources and VPN clients resolve private endpoint FQDNs via private DNS zones.
# Only created when enable_dns_resolver = true (resolver must exist first).
resource "azurerm_virtual_network_dns_servers" "hub" {
  count              = var.enable_dns_resolver ? 1 : 0
  virtual_network_id = module.hub_vnet.vnet_id
  dns_servers        = [azurerm_private_dns_resolver_inbound_endpoint.hub[0].ip_configurations[0].private_ip_address]
}

# module "network_connectivity" {
#   source              = "../../modules/network"
#   resource_group_name = azurerm_resource_group.main.name
#   resource_group_id   = azurerm_resource_group.main.id
#   vnet_address_space  = var.vnet_address_space
#   project             = var.project
#   environment         = var.environment
#   region              = var.region
#   subnets             = var.subnets
#   default_tags        = local.default_tags
#   private_dns_zones   = var.private_dns_zones
# }