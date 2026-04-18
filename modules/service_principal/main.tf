# Service principal module

# Get current project configuration
data "azurerm_client_config" "current" {}

# Create Azure AD Application
resource "azuread_application" "this" {
  display_name = "sp-${var.project}-${var.environment}"
  owners       = [data.azurerm_client_config.current.object_id]

  # Optional: Add API permissions if needed
  # required_resource_access {
  #   resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph
  #   resource_access {
  #     id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
  #     type = "Scope"
  #   }
  # }
}

# Create Service Principal
resource "azuread_service_principal" "this" {
  client_id                    = azuread_application.this.client_id
  app_role_assignment_required = false
  owners                       = [data.azurerm_client_config.current.object_id]
}

# --- Certificate credential path ---

resource "azurerm_key_vault_certificate" "sp_cert" {
  count        = var.credential_type == "certificate" ? 1 : 0
  name         = "cert-${var.project}-${var.environment}"
  key_vault_id = var.key_vault_id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        lifetime_percentage = 10
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      extended_key_usage = ["1.3.6.1.5.5.7.3.2"] #"1.3.6.1.5.5.7.3.1",

      key_usage = [
        #"cRLSign",
        #"dataEncipherment",
        #"digitalSignature",
        #"keyCertSign",
        "keyAgreement",
        "keyEncipherment",
      ]

      subject_alternative_names {
        dns_names = []
      }

      subject            = "CN=${var.project}-${var.environment}"
      validity_in_months = 1
    }
  }
}

resource "azuread_application_certificate" "sp_cert" {
  count          = var.credential_type == "certificate" ? 1 : 0
  application_id = azuread_application.this.id
  type           = "AsymmetricX509Cert"
  encoding       = "hex" # Recommended when integrating with key vault
  value          = azurerm_key_vault_certificate.sp_cert[0].certificate_data

  lifecycle {
    create_before_destroy = true
    replace_triggered_by  = [azurerm_key_vault_certificate.sp_cert[0].certificate_data]
  }
}

# --- Client secret credential path ---

resource "azuread_application_password" "sp_secret" {
  count          = var.credential_type == "secret" ? 1 : 0
  application_id = azuread_application.this.id
  display_name   = "secret-${var.project}-${var.environment}"

  rotate_when_changed = {
    rotation = plantimestamp()
  }
}

resource "azurerm_key_vault_secret" "sp_secret" {
  count        = var.credential_type == "secret" ? 1 : 0
  name         = "secret-${var.project}-${var.environment}"
  value        = azuread_application_password.sp_secret[0].value
  key_vault_id = var.key_vault_id
}

# Create role assignments for the service principal
resource "azurerm_role_assignment" "sp_roles" {
  for_each = var.role_assignments

  scope                = each.value.scope
  role_definition_name = each.value.role_definition_name
  principal_id         = azuread_service_principal.this.object_id
}

# # Grant the service principal Key Vault Secrets User role to read its own certificate
# resource "azurerm_role_assignment" "sp_cert_reader" {
#   scope                = azurerm_key_vault_certificate.sp_cert.secret_id
#   role_definition_name = "Key Vault Secrets User"
#   principal_id         = azuread_service_principal.this.object_id
# }
