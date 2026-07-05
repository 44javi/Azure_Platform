# linux_vms module variables

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "region" {
  description = "Region where resources will be created"
  type        = string
}

variable "project" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment for resources"
  type        = string
}

variable "default_tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "key_vault_id" {
  description = "Key Vault that stores the generated break-glass SSH private keys"
  type        = string
}

variable "virtual_machines" {
  description = "Linux VMs to create, keyed by short name (used in resource naming). Add new VMs here without changing module code."
  type = map(object({
    subnet_id      = string
    size           = optional(string, "Standard_B2s")
    admin_username = optional(string, "azureadmin")
    zone           = optional(string)

    # Static private IP; leave null for dynamic allocation
    private_ip_address = optional(string)
    create_public_ip   = optional(bool, false)

    # NIC-level IP forwarding, required when the VM routes traffic for other
    # networks (e.g. a VPN server forwarding into the VNet)
    enable_ip_forwarding = optional(bool, false)

    # Cloud-init user data (plain text; the module base64-encodes it).
    # Changing it forces VM replacement.
    custom_data = optional(string)

    os_disk = optional(object({
      storage_account_type = optional(string, "StandardSSD_LRS")
      disk_size_gb         = optional(number, 64)
    }), {})

    source_image_reference = optional(object({
      publisher = optional(string, "Canonical")
      offer     = optional(string, "ubuntu-24_04-lts")
      sku       = optional(string, "server")
      version   = optional(string, "latest")
    }), {})

    # Entra ID SSH login (AADSSHLoginForLinux extension); SSH key in Key Vault stays as break-glass
    entra_id_login = optional(bool, true)

    # Object IDs granted "Virtual Machine Administrator Login" / "Virtual Machine User Login" on this VM
    admin_login_principal_ids = optional(list(string), [])
    user_login_principal_ids  = optional(list(string), [])
  }))
  default = {}
}
