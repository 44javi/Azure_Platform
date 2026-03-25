# Random name for SSH key
resource "random_pet" "ssh_key_name" {
  length = 2
}

# # Create the SSH public key in Azure
# resource "azapi_resource" "ssh_public_key" {
#   type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
#   name      = random_pet.ssh_key_name.id
#   location  = var.region
#   parent_id = var.resource_group_id
# }

# # Generate the SSH key pair
# resource "azapi_resource_action" "ssh_public_key_gen" {
#   type        = "Microsoft.Compute/sshPublicKeys@2022-11-01"
#   resource_id = azapi_resource.ssh_public_key.id
#   action      = "generateKeyPair"
#   method      = "POST"

#   response_export_values = ["*"]
# }

# locals {
#   ssh_private_key = azapi_resource_action.ssh_public_key_gen.output["privateKey"]
#   ssh_public_key  = azapi_resource_action.ssh_public_key_gen.output["publicKey"]
# }

# resource "local_file" "private_key" {
#   content         = sensitive(local.ssh_private_key)
#   filename        = "${path.module}/private.pem"
#   file_permission = "0600"
# }

resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Place private key in azure key vault
resource "azurerm_key_vault_secret" "ssh_private" {
  name         = "${var.project}-private"
  value        = tls_private_key.this.private_key_pem
  key_vault_id = var.key_vault_id
}

resource "azurerm_key_vault_secret" "ssh_public" {
  name         = "${var.project}-public"
  value        = tls_private_key.this.public_key_openssh
  key_vault_id = var.key_vault_id
}

# Create the Virtual Machine
resource "azurerm_linux_virtual_machine" "this" {
  name                = "vm-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  size                = "Standard_B1s" #"Standard_D4s_v3"
  admin_username      = var.username

  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id,
  ]

  admin_ssh_key {
    username   = var.username
    public_key = tls_private_key.this.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    # disk_size_gb         = 256
  }

  source_image_reference {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-LVM"
    version   = "latest"
  }

  # custom_data = base64encode(<<-EOF
  # #!/bin/bash
  # # Script to expand LVM to use full disk on RHEL VMs using percentages

  # # Write output to log file and terminal
  # exec > >(tee /var/log/disk-expansion.log) 2>&1
  # set -x

  # echo "Starting disk expansion script..."

  # # Wait for the system to settle
  # sleep 60

  # # Auto-detect the correct disk with LVM containing the root filesystem
  # ROOT_MOUNT=$(df -h / | grep dev | awk '{print $1}')
  # ROOT_VG=$(echo $ROOT_MOUNT | cut -d- -f1 | cut -d/ -f4)
  # ROOT_PV=$(pvs | grep $ROOT_VG | awk '{print $1}')
  # ROOT_DISK=$(echo $ROOT_PV | sed 's/[0-9]*$//')
  # ROOT_PART_NUM=$(echo $ROOT_PV | grep -o '[0-9]*$')

  # echo "Detected root filesystem on $ROOT_MOUNT"
  # echo "Volume Group: $ROOT_VG"
  # echo "Physical Volume: $ROOT_PV"
  # echo "Disk: $ROOT_DISK"
  # echo "Partition: $ROOT_PART_NUM"

  # # Expand the LVM partition 
  # echo "Expanding partition $ROOT_PART_NUM on disk $ROOT_DISK..."
  # growpart $ROOT_DISK $ROOT_PART_NUM || echo "Partition expansion failed, but continuing..."

  # # Resize the volume to use all space in the expanded partition
  # echo "Resizing volume $ROOT_PV..."
  # pvresize $ROOT_PV || echo "PV resize failed, but continuing with existing space..."

  # # Extend logical volumes with higher percentages to use ~90% of space
  # echo "Extending logical volumes by percentage..."

  # # For /usr - Applications (35% of available space)
  # echo "Setting /usr to 35% of available space"
  # lvresize -l +35%FREE /dev/mapper/$ROOT_VG-usrlv || true
  # xfs_growfs /usr

  # # For /home - User files (35% of available space)
  # echo "Setting /home to 35% of available space"
  # lvresize -l +35%FREE /dev/mapper/$ROOT_VG-homelv || true
  # xfs_growfs /home

  # # For /var - Logs (25% of available space)
  # echo "Setting /var to 25% of available space"
  # lvresize -l +25%FREE /dev/mapper/$ROOT_VG-varlv || true
  # xfs_growfs /var

  # # For /tmp - Temporary files (15% of available space)
  # echo "Setting /tmp to 15% of available space"
  # lvresize -l +15%FREE /dev/mapper/$ROOT_VG-tmplv || true
  # xfs_growfs /tmp

  # # Log the final results
  # echo "Final disk configuration:"
  # lsblk
  # vgs
  # lvs
  # df -h
  # EOF
  # )

  computer_name                   = "vm-${var.project}-${var.environment}"
  disable_password_authentication = true

  tags = var.default_tags
}


# Create Public IP for VM
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "pip-${var.project}-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.default_tags
}

# Create the Network Interface
resource "azurerm_network_interface" "vm_nic" {
  name                = "nic-${var.project}-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.public_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vm_private_ip
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
  }
  tags = var.default_tags
}

# Collects vm logs and sends them to the log workspace
resource "azurerm_monitor_data_collection_rule" "syslog" {
  name                = "dcr_${var.project}_${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.log_location
  destinations {
    log_analytics {
      workspace_resource_id = var.log_analytics_id
      name                  = "syslog-location"
    }
  }
  data_sources {
    syslog {
      name           = "syslog_datasource_${var.project}"
      facility_names = ["*"]
      log_levels     = ["*"]
      streams        = ["Microsoft-Syslog"]
    }
  }
  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["syslog-location"]
  }
  tags = var.default_tags
}
# Association and agent installation
resource "azurerm_monitor_data_collection_rule_association" "vm_syslog_association" {
  name                    = "dcr_syslog_${var.project}_${var.environment}"
  target_resource_id      = azurerm_linux_virtual_machine.this.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.syslog.id
  description             = "Association between Linux VM and syslog data collection rule"
}
resource "azurerm_virtual_machine_extension" "azure_monitor_agent" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.34"
  auto_upgrade_minor_version = true
  tags                       = var.default_tags
}
