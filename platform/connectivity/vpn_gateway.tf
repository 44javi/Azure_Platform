locals {
  vpn_use_aad  = contains(var.vpn_auth_types, "AAD")
  vpn_use_cert = contains(var.vpn_auth_types, "Certificate")
}

resource "azurerm_public_ip" "vpn_gateway" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "pip-vpngw-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.default_tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "vpngw-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vpn_gateway_sku
  bgp_enabled         = false
  active_active       = false

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = module.network_connectivity.subnet_ids["GatewaySubnet"]
  }

  vpn_client_configuration {
    address_space        = [var.vpn_client_address_pool]
    vpn_client_protocols = var.vpn_client_protocols
    vpn_auth_types       = var.vpn_auth_types

    # Entra ID (AAD) — only populated when vpn_auth_types includes "AAD"
    aad_tenant   = local.vpn_use_aad ? "https://login.microsoftonline.com/${var.tenant_id}/" : null
    aad_audience = local.vpn_use_aad ? var.vpn_aad_audience : null
    aad_issuer   = local.vpn_use_aad ? "https://sts.windows.net/${var.tenant_id}/" : null

    # Certificate auth — only populated when vpn_auth_types includes "Certificate"
    dynamic "root_certificate" {
      for_each = local.vpn_use_cert && var.vpn_root_cert_data != null ? [1] : []
      content {
        name             = "P2SRootCert"
        public_cert_data = var.vpn_root_cert_data
      }
    }
  }

  lifecycle {
    precondition {
      condition     = contains(keys(module.network_connectivity.subnet_ids), "GatewaySubnet")
      error_message = "GatewaySubnet must be present in var.subnets when enable_vpn_gateway = true."
    }
    precondition {
      condition     = !local.vpn_use_aad || var.tenant_id != null
      error_message = "tenant_id must be set when vpn_auth_types includes 'AAD'."
    }
    # AAD auth only works with OpenVPN — IkeV2 and SSTP require Certificate or Radius
    precondition {
      condition     = !local.vpn_use_aad || contains(var.vpn_client_protocols, "OpenVPN")
      error_message = "AAD (Entra ID) auth requires OpenVPN protocol. Add 'OpenVPN' to vpn_client_protocols."
    }
  }

  tags = local.default_tags
}
