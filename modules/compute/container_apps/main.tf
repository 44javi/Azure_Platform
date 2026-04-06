# Container App Environment is the shared runtime boundary for one or more Container Apps.
# It provisions the underlying infrastructure (networking, logging) that apps share.
resource "azurerm_container_app_environment" "main" {
  name                       = "cae-${var.project}-${var.environment}"
  location                        = var.region
  resource_group_name             = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id != null && var.log_analytics_workspace_id != "" ? var.log_analytics_workspace_id : null
  logs_destination = var.logs_destination

  tags = var.default_tags
}

resource "azurerm_container_app" "main" {
  name                         = "ca-${var.project}-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = var.resource_group_name

  # Single keeps one active revision at a time. Multiple allows traffic splitting across revisions.
  revision_mode = var.revision_mode

  # Ignore image changes so CI/CD deployments outside Terraform do not trigger drift.
  lifecycle {
    ignore_changes = [
      template[0].container[0].image
    ]
  }

  template {
    container {
      name  = "${var.project}-${var.environment}"
      image = "${var.docker_usr}/${var.container_image}"
      cpu    = var.cpu
      memory = var.memory

      env {
        name  = "PORT"
        value = tostring(var.port)
      }
    }

    # min_replicas 0 enables scale to zero. min_replicas 1 keeps the app always warm.
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  ingress {
    # external_enabled true exposes the app on a public FQDN. false restricts to internal vnet only.
    external_enabled = var.external_ingress
    target_port      = var.port

    traffic_weight {
      # latest_revision true routes all traffic to the most recently deployed revision.
      latest_revision = true
      percentage      = 100
    }
  }

  tags = var.default_tags
}

# Custom domain binds a user-owned domain to the container app.
# Azure provisions a free managed TLS certificate when certificate_binding_type is SniEnabled.
# Set enable_custom_domain = false on initial deploy to skip binding until DNS is ready.
resource "azurerm_container_app_custom_domain" "apex" {
  count            = var.enable_custom_domain ? 1 : 0
  name             = var.custom_domain
  container_app_id = azurerm_container_app.main.id

  certificate_binding_type = var.certificate_binding_type

  lifecycle {
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}

resource "azurerm_container_app_custom_domain" "www" {
  count            = var.enable_custom_domain ? 1 : 0
  name             = var.custom_domain_www
  container_app_id = azurerm_container_app.main.id

  certificate_binding_type = var.certificate_binding_type

  lifecycle {
    ignore_changes = [certificate_binding_type, container_app_environment_certificate_id]
  }
}
