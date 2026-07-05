# linux_vms module

locals {
  # Only create public IPs for VMs that opt in
  vms_with_public_ip = { for k, v in var.virtual_machines : k => v if v.create_public_ip }

  # Only install the Entra ID login extension where enabled
  vms_with_entra_login = { for k, v in var.virtual_machines : k => v if v.entra_id_login }

  # Flattened VM/principal pairs for Entra ID login role assignments
  entra_admin_logins = merge([
    for vm_key, vm in var.virtual_machines : {
      for principal_id in vm.admin_login_principal_ids :
      "${vm_key}-${principal_id}" => { vm_key = vm_key, principal_id = principal_id }
    }
  ]...)

  entra_user_logins = merge([
    for vm_key, vm in var.virtual_machines : {
      for principal_id in vm.user_login_principal_ids :
      "${vm_key}-${principal_id}" => { vm_key = vm_key, principal_id = principal_id }
    }
  ]...)
}

# Break-glass SSH keypair — one per VM. Entra ID login is the day-to-day
# access path; Azure still requires an admin SSH key at provision time.
resource "tls_private_key" "vms" {
  for_each = var.virtual_machines

  algorithm = "RSA"
  rsa_bits  = 4096
}

# Private key stored in Key Vault. No automatic rotation: taint/replace
# tls_private_key.vms[<key>] to rotate; a new secret version is created.
resource "azurerm_key_vault_secret" "ssh_private_key" {
  for_each = var.virtual_machines

  name         = "vm-${each.key}-${var.project}-${var.environment}-ssh-private-key"
  value        = tls_private_key.vms[each.key].private_key_pem
  key_vault_id = var.key_vault_id
  content_type = "SSH private key (PEM) for ${each.value.admin_username}@vm-${each.key}-${var.project}-${var.environment}"

  tags = var.default_tags
}

# Public IPs — only created for VMs with create_public_ip = true
resource "azurerm_public_ip" "vms" {
  for_each = local.vms_with_public_ip

  name                = "pip-vm-${each.key}-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = each.value.zone != null ? [each.value.zone] : null

  tags = var.default_tags
}

# NICs — one per VM
resource "azurerm_network_interface" "vms" {
  for_each = var.virtual_machines

  name                  = "nic-vm-${each.key}-${var.project}-${var.environment}"
  resource_group_name   = var.resource_group_name
  location              = var.region
  ip_forwarding_enabled = each.value.enable_ip_forwarding

  ip_configuration {
    name                          = "internal"
    subnet_id                     = each.value.subnet_id
    private_ip_address_allocation = each.value.private_ip_address != null ? "Static" : "Dynamic"
    private_ip_address            = each.value.private_ip_address
    public_ip_address_id          = each.value.create_public_ip ? azurerm_public_ip.vms[each.key].id : null
  }

  tags = var.default_tags
}

resource "azurerm_linux_virtual_machine" "vms" {
  for_each = var.virtual_machines

  name                = "vm-${each.key}-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  size                = each.value.size
  zone                = each.value.zone

  admin_username                  = each.value.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = each.value.admin_username
    public_key = tls_private_key.vms[each.key].public_key_openssh
  }

  network_interface_ids = [azurerm_network_interface.vms[each.key].id]

  custom_data = each.value.custom_data != null ? base64encode(each.value.custom_data) : null

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  # Required for Entra ID login; harmless otherwise
  identity {
    type = "SystemAssigned"
  }

  # Managed storage account boot diagnostics
  boot_diagnostics {}

  tags = var.default_tags
}

# Entra ID SSH login extension — only for VMs with entra_id_login = true
resource "azurerm_virtual_machine_extension" "entra_login" {
  for_each = local.vms_with_entra_login

  name                       = "AADSSHLoginForLinux"
  virtual_machine_id         = azurerm_linux_virtual_machine.vms[each.key].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADSSHLoginForLinux"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  tags = var.default_tags
}

# Entra ID login role assignments, scoped to the individual VM
resource "azurerm_role_assignment" "admin_login" {
  for_each = local.entra_admin_logins

  scope                = azurerm_linux_virtual_machine.vms[each.value.vm_key].id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = each.value.principal_id
}

resource "azurerm_role_assignment" "user_login" {
  for_each = local.entra_user_logins

  scope                = azurerm_linux_virtual_machine.vms[each.value.vm_key].id
  role_definition_name = "Virtual Machine User Login"
  principal_id         = each.value.principal_id
}
