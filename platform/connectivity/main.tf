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
