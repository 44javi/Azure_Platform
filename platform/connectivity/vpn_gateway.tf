locals {
  vpn_use_aad  = contains(var.vpn_auth_types, "AAD")
  vpn_use_cert = contains(var.vpn_auth_types, "Certificate")

  _raw_cert = try(data.azurerm_key_vault_secret.p2s_cert[0].value, null)
  # KV-generated PEM bundles include the private key alongside the cert; extract only the certificate block.
  # Falls back to the raw value when the secret already holds bare base64 DER (no PEM headers).
  _cert_b64 = local._raw_cert != null ? try(
    regex("-----BEGIN CERTIFICATE-----([\\s\\S]*?)-----END CERTIFICATE-----", local._raw_cert)[0],
    local._raw_cert
  ) : null
  # Azure requires bare base64 DER with no whitespace.
  vpn_cert_public_data = local._cert_b64 != null ? replace(replace(replace(local._cert_b64, "\n", ""), "\r", ""), " ", "") : null
}

resource "azurerm_public_ip" "vpn_gateway" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "pip-vpngw-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.default_tags
}

resource "azurerm_virtual_network_gateway" "vpn" {
  count               = var.enable_vpn_gateway ? 1 : 0
  name                = "vpngw-${var.project}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = var.region
  type                = var.vpn_gateway_type
  vpn_type            = "RouteBased"
  sku                 = var.vpn_gateway_sku
  bgp_enabled         = var.vpn_gateway_bgp_enabled
  active_active       = var.vpn_gateway_active_active

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
      for_each = local.vpn_use_cert && local.vpn_cert_public_data != null ? [1] : []
      content {
        name             = "P2SRootCert"
        public_cert_data = local.vpn_cert_public_data
      }
    }
  }

  lifecycle {
    # The root CA cert is managed outside Terraform (Key Vault cannot store CertSign certs).
    # Use the upload-root-cert.ps1 script and az network vnet-gateway root-cert commands to rotate it.
    ignore_changes = [vpn_client_configuration[0].root_certificate]

    precondition {
      condition     = contains(keys(module.network_connectivity.subnet_ids), "GatewaySubnet")
      error_message = "GatewaySubnet must be present in var.subnets when enable_vpn_gateway = true."
    }
    precondition {
      condition     = !local.vpn_use_aad || var.tenant_id != null
      error_message = "tenant_id must be set when vpn_auth_types includes 'AAD'."
    }
    # AAD auth only works with OpenVPN — IkeV2 requires Certificate or Radius (SSTP retired Mar 31 2026)
    precondition {
      condition     = !local.vpn_use_aad || contains(var.vpn_client_protocols, "OpenVPN")
      error_message = "AAD (Entra ID) auth requires OpenVPN protocol. Add 'OpenVPN' to vpn_client_protocols."
    }
    precondition {
      condition     = !local.vpn_use_cert || (var.mg_kv_name != null && var.mg_kv_rg != null)
      error_message = "Certificate auth requires mg_kv_name and mg_kv_rg to be set, pointing to the central management Key Vault."
    }
  }

  tags = local.default_tags
}
