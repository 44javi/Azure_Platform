############################################
# Azure Front Door Premium
# - Public ingress for chat.cyberneticparts.com
# - Private Link to App Service (requires Premium)
# - Managed WAF policy attached to endpoint
############################################
resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = "afd-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  sku_name            = "Premium_AzureFrontDoor"
  tags                = var.default_tags
}

resource "azurerm_cdn_frontdoor_endpoint" "this" {
  name                     = "fde-${var.project}-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  tags                     = var.default_tags
}

resource "azurerm_cdn_frontdoor_origin_group" "app" {
  name                     = "og-app-${var.project}-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    interval_in_seconds = 60
    path                = "/"
    protocol            = "Https"
    request_type        = "HEAD"
  }
}

# Origin with Private Link to the Web App
resource "azurerm_cdn_frontdoor_origin" "app" {
  name                          = "origin-app-${var.project}-${var.environment}"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.app.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = azurerm_windows_web_app.this.default_hostname
  origin_host_header             = azurerm_windows_web_app.this.default_hostname
  http_port                      = 80
  https_port                     = 443
  priority                       = 1
  weight                         = 1000

  private_link {
    request_message        = "Front Door to App Service"
    target_type            = "sites"
    location               = var.region
    private_link_target_id = azurerm_windows_web_app.this.id
  }
}

# Custom domain (chat.cyberneticparts.com) with managed cert
resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  name                     = "cd-${replace(var.custom_domain, ".", "-")}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  host_name                = var.custom_domain

  tls {
    certificate_type    = "ManagedCertificate"
    minimum_tls_version = "TLS12"
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  name                          = "route-${var.project}-${var.environment}"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.this.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.app.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.app.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = [azurerm_cdn_frontdoor_custom_domain.this.id]
  link_to_default_domain          = true
}

resource "azurerm_cdn_frontdoor_custom_domain_association" "this" {
  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.this.id
  cdn_frontdoor_route_ids        = [azurerm_cdn_frontdoor_route.this.id]
}

############################################
# WAF Policy
############################################
resource "azurerm_cdn_frontdoor_firewall_policy" "this" {
  name                              = "waf${var.project}${var.environment}"
  resource_group_name               = var.resource_group_name
  sku_name                          = azurerm_cdn_frontdoor_profile.this.sku_name
  enabled                           = true
  mode                              = "Prevention"
  redirect_url                      = null
  custom_block_response_status_code = 403
  tags                              = var.default_tags

  managed_rule {
    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {
    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }
}

resource "azurerm_cdn_frontdoor_security_policy" "this" {
  name                     = "secpol-${var.project}-${var.environment}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.this.id
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_custom_domain.this.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}