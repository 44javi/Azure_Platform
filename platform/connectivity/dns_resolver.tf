resource "azurerm_private_dns_resolver" "hub" {
  count               = var.enable_dns_resolver ? 1 : 0
  name                = "dnsresolver-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  virtual_network_id  = module.network_connectivity.vnet_id
  tags                = local.default_tags
}

# Inbound endpoint — gets a real private IP inside the hub VNet (10.79.254.x).
# VPN clients use this IP for DNS, it's reachable through the tunnel, and the
# resolver forwards to 168.63.129.16 internally from within Azure where it IS accessible.
resource "azurerm_private_dns_resolver_inbound_endpoint" "hub" {
  count                   = var.enable_dns_resolver ? 1 : 0
  name                    = "inbound-${var.project}-${var.environment}"
  private_dns_resolver_id = azurerm_private_dns_resolver.hub[0].id
  location                = var.region

  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = module.network_connectivity.subnet_ids["dns_resolver"]
  }

  lifecycle {
    precondition {
      condition     = contains(keys(module.network_connectivity.subnet_ids), "dns_resolver")
      error_message = "dns_resolver subnet must be present in var.subnets when enable_dns_resolver = true."
    }
  }

  tags = local.default_tags
}
