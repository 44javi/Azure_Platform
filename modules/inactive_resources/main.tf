/* inactive_resources module

# For Azure Backend set up

# Creates a Resource Group

resource "azurerm_resource_group" "state" {
  name     = "rg-state-${var.environment}"
  location = var.region

  tags = local.default_tags
}

# for tags
locals {
  default_tags = {
    owner       = var.owner
    environment = var.environment
    project      = var.project
    region      = var.region
    created_by  = "Terraform"
  }
}

# Random string for storage names
resource "random_string" "this" {
  length  = 6
  special = false
  upper   = false
}


data "azurerm_project_config" "current" {}

# Storage Blob Data Contributor - for state file operations
resource "azurerm_role_assignment" "current_user_blob" {
  scope                = azurerm_storage_account.state.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_project_config.current.object_id
}

# Storage account for state
resource "azurerm_storage_account" "state" {
  name                = "ststate${random_string.this.result}"
  location            = var.region
  resource_group_name = azurerm_resource_group.main.name

  account_tier                      = "Standard"
  account_kind                      = "StorageV2"
  account_replication_type          = "GRS"
  https_traffic_only_enabled        = true
  min_tls_version                   = "TLS1_2"
  shared_access_key_enabled         = true
  default_to_oauth_authentication   = true
  infrastructure_encryption_enabled = false
  allow_nested_items_to_be_public   = false
  public_network_access_enabled     = true # false blocks access to containers on the portal




  blob_properties {
    versioning_enabled            = true
    change_feed_enabled           = true
    change_feed_retention_in_days = 30
    last_access_time_enabled      = true

    delete_retention_policy {
      days = 30
    }
    container_delete_retention_policy {
      days = 30
    }
  }
  sas_policy {
    expiration_period = "00.02:00:00"
    expiration_action = "Log"
  }
}

# Create container in the storage account for state
resource "azurerm_storage_container" "this" {
  name                  = "${var.region}-state-management"
  storage_account_id    = azurerm_storage_account.state.id
  container_access_type = "private"
}




-----------------------------------------------------------------------------------------------------------------------------------

# Generate a random string for the VM name environment
resource "random_string" "vm_name_environment" {
  length  = 8
  upper   = false
  special = false
  numeric = true
}

# Create the SSH public key in Azure
resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = var.resource_group_location
  parent_id = var.resource_group_id
}

# Generate the SSH key pair
resource "azapi_resource_action" "ssh_public_key_gen" {
  type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id = azapi_resource.ssh_public_key.id
  action      = "generateKeyPair"
  method      = "POST"

  response_export_values = ["publicKey", "privateKey"]
}



# Store the SSH public key locally
resource "local_file" "ssh_public_key" {
  filename = "${path.module}/ssh_public_key.pem"
  content  = azapi_resource_action.ssh_public_key_gen.output.publicKey

  depends_on = [azapi_resource_action.ssh_public_key_gen]
}

# Store the SSH private key locally
resource "local_file" "ssh_private_key" {
  filename = "${path.module}/ssh_private_key.pem"
  content  = azapi_resource_action.ssh_public_key_gen.output.privateKey

  depends_on = [azapi_resource_action.ssh_public_key_gen]
}


# Create the Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "dev-vm-${random_string.vm_name_environment.result}"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  size                = "Standard_D4s_v3"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = azapi_resource_action.ssh_public_key_gen.output.publicKey
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 125
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "8-LVM"
    version   = "latest"
  }

  computer_name                   = "dev-vm"
  disable_password_authentication = true
}

/*
 # Create the Public IP
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "jp-vm-public-ip"
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  allocation_method   = "Static"   
  sku                 = "Standard" 
}

# Create the Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "jp-vm-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
    #public_ip_address_id = azurerm_public_ip.vm_public_ip.id
  }
}

# Output the generated SSH public key
output "ssh_public_key" {
  value = azapi_resource_action.ssh_public_key_gen.output.publicKey
}


--------------------------------------------------------------------------------------------------------------------------------------

# Site to Site VPN 

# Key for VPN
resource "random_password" "shared_key" {
  length  = 32
  special = true
}

output "vpn_shared_key" {
  value     = random_password.shared_key.result
  sensitive = true
}

# Create the Gateway Subnet for the VPN
resource "azurerm_subnet" "gateway_vpn" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.dev-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/27"]
}

# Create Public IP for VPN Gateway
resource "azurerm_public_ip" "vpn_gateway_ip" {
  name                = "vpn-gateway-ip"
  resource_group_name = azurerm_resource_group.dev-rg.name
  location            = azurerm_resource_group.dev-rg.location
  allocation_method   = "Static"  
  sku                 = "Standard" 
}

# Create the Azure VPN Gateway
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "dev-vpn-gateway"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name
  type                = "Vpn" # ExpressRoute for private connection to azure that does not go through public internet
  vpn_type            = "RouteBased"
  active_active       = false
  enable_bgp          = false
  sku                 = "VpnGw1"  # VpnGw1 650Mbps, VpnGw2 1Gbps, VpnGw3 1.25Gbps
  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id           = azurerm_public_ip.vpn_gateway_ip.id
    subnet_id                      = azurerm_subnet.gateway_subnet.id
  }
}

# Create the Local Network Gateway (On-Premises Network)
resource "azurerm_local_network_gateway" "local_network_gateway" {
  name                = "on-prem-lng"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name

  gateway_address     = "192.168.1.9"  # Replace with on-premises VPN device's public IP
  address_space       = ["192.168.1.0/24"]    # Replace with on-premises network address space
}

# Create the VPN Connection (Azure to On-Premises)
resource "azurerm_virtual_network_gateway_connection" "vpn_connection" {
  name                = "dev-s2s-vpn-connection"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name

  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.local_network_gateway.id

  type                = "IPsec"
  connection_protocol = "IKEv2"
  shared_key          = "random_password.shared_key.result"  # Must be the same on both sides (Azure and on-premises)

  ipsec_policy {
    sa_lifetime            = 3600
    ipsec_encryption       = "AES256"
    ipsec_integrity        = "SHA256"
    ike_encryption         = "AES256"
    ike_integrity          = "SHA256"
    dh_group               = "DHGroup14" # or DHGroup19 for (ECC)
    pfs_group              = "PFS14" # or PFS19 uses Elliptic Curve Cryptography
  }
}

-----------------------------------------------------------------------------------------------------------------------

*/




# data_pipeline




/*




/*




terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.9"
    }
  }
}

module "jobs" {
  source = "./jobs"

  providers = {
    databricks = databricks
  }

  project                    = var.project
  environment                    = var.environment
  databricks_identity_id = azurerm_user_assigned_identity.databricks.project_id
  tenant_id                 = data.azurerm_project_config.current.tenant_id
  notebook_path            = databricks_notebook.gzip_to_parquet.path
  storage_account_name     = azurerm_storage_account.adls.name
  bronze_container         = var.bronze_container
  gold_container          = var.gold_container

  depends_on = [
    azurerm_databricks_workspace.this,
    databricks_notebook.gzip_to_parquet,
    azurerm_role_assignment.databricks_adls_access
  ]
}




locals {
  notebook_template = file("${path.module}/notebooks/gzip_to_parquet.py")
  notebook_content = replace(
    replace(
      replace(
        replace(
          replace(
            local.notebook_template,
            "STORAGE_ACCOUNT_NAME",
            azurerm_storage_account.adls.name
          ),
          "BRONZE_CONTAINER_NAME",
          var.bronze_container
        ),
        "GOLD_CONTAINER_NAME",
        var.gold_container
      ),
      "MANAGED_IDENTITY_project_ID",
      azurerm_user_assigned_identity.databricks.project_id
    ),
    "TENANT_ID",
    data.azurerm_project_config.current.tenant_id
  )
}

resource "databricks_notebook" "gzip_to_parquet" {
  path     = "/Shared/transformation/gzip_to_parquet"
  language = "PYTHON"
  source   = "${path.module}/notebooks/gzip_to_parquet.py"

  depends_on = [
    azurerm_databricks_workspace.this,
    azurerm_storage_container.bronze,
    azurerm_storage_container.gold
  ]
}



# Databricks Job using a Job Cluster
resource "databricks_job" "gzip_to_parquet_job" {
  provider = databricks.workspace
  name     = "gzip-to-parquet-job"

  # Job Clusters automatically terminate after finishing the job
  new_cluster {
    spark_version = "14.3.x-scala2.12"
    node_type_id  = "Standard_D3_v2" # Small compute
    spark_conf = {
      # Single-node
      "spark.databricks.cluster.profile" : "singleNode"
      "spark.master" : "local[*]"
    }

    custom_tags = {
      "ResourceClass" = "SingleNode"
    }

    # Subscription quota limits prevented autoscale and couldn't find smaller compute to use
    #autoscale {
    #min_workers = 1
    #max_workers = 1
    #}
  }

  notebook_task {
    notebook_path = "/Workspace/shared/Transformations" #TBD
  }
  
  schedule {
    quartz_cron_expression = "0 15 * * * ?"  # Runs 15 minutes after every hour
    timezone_id            = "UTC"
  }
  
  depends_on = [
    azurerm_databricks_workspace.databricks
  ]
}


# Private Endpoint for Databricks 
resource "azurerm_private_endpoint" "databricks_private_endpoint" {
  name                = "databricks-pe"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name
  subnet_id           = azurerm_subnet.databricks_public_subnet.id

  private_service_connection {
    name                           = "databricksConnection"
    private_connection_resource_id = azurerm_databricks_workspace.databricks.id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }
}


# Synapse Analytics Workspace
resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                               = "synapse-workspace-${random_string.unique_environment.result}"
  resource_group_name                = azurerm_resource_group.dev-rg.name
  location                           = azurerm_resource_group.dev-rg.location
  storage_data_lake_gen2_filesystem_id = "https://${azurerm_storage_account.adls_storage.name}.dfs.core.windows.net/${azurerm_storage_data_lake_gen2_filesystem.adls_filesystem.name}"

  identity {
    type = "SystemAssigned"
  }
}

# Synapse Private Endpoint
resource "azurerm_private_endpoint" "synapse_private_endpoint" {
  name                = "synapse-pe"
  location            = azurerm_resource_group.dev-rg.location
  resource_group_name = azurerm_resource_group.dev-rg.name
  subnet_id           = azurerm_subnet.subnet.id

  private_service_connection {
    name                           = "synapseConnection"
    private_connection_resource_id = azurerm_synapse_workspace.synapse_workspace.id
    subresource_names              = ["dev"]
    is_manual_connection           = false
  }
}

*/
