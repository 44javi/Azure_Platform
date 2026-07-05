# linux_vms module outputs

output "vm_ids" {
  description = "Map of VM key to virtual machine resource ID"
  value       = { for k, v in azurerm_linux_virtual_machine.vms : k => v.id }
}

output "vm_names" {
  description = "Map of VM key to virtual machine name"
  value       = { for k, v in azurerm_linux_virtual_machine.vms : k => v.name }
}

output "principal_ids" {
  description = "Map of VM key to system-assigned managed identity principal ID, for granting the VM access to other resources"
  value       = { for k, v in azurerm_linux_virtual_machine.vms : k => v.identity[0].principal_id }
}

output "private_ip_addresses" {
  description = "Map of VM key to primary private IP address"
  value       = { for k, v in azurerm_network_interface.vms : k => v.private_ip_address }
}

output "public_ip_addresses" {
  description = "Map of VM key to public IP address. Only contains VMs with create_public_ip = true."
  value       = { for k, v in azurerm_public_ip.vms : k => v.ip_address }
}

output "admin_usernames" {
  description = "Map of VM key to admin username, for use with the break-glass SSH key"
  value       = { for k, v in azurerm_linux_virtual_machine.vms : k => v.admin_username }
}

output "ssh_private_key_secret_names" {
  description = "Map of VM key to Key Vault secret name holding the break-glass SSH private key"
  value       = { for k, v in azurerm_key_vault_secret.ssh_private_key : k => v.name }
}

output "ssh_private_key_secret_ids" {
  description = "Map of VM key to Key Vault secret ID holding the break-glass SSH private key"
  value       = { for k, v in azurerm_key_vault_secret.ssh_private_key : k => v.id }
}

output "ssh_public_keys" {
  description = "Map of VM key to OpenSSH public key of the break-glass keypair"
  value       = { for k, v in tls_private_key.vms : k => v.public_key_openssh }
}
