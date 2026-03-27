# network module outputs

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

# Full map of subnet IDs — preferred for new references: module.network.subnet_ids["my_subnet"]
output "subnet_ids" {
  description = "Map of subnet key to subnet ID for all subnets managed by this module"
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

# Convenience outputs for the three standard subnets (backward compatibility)
output "subnet_id" {
  description = "Private subnet ID"
  value       = try(azurerm_subnet.subnets["private"].id, null)
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = try(azurerm_subnet.subnets["public"].id, null)
}

output "bastion_subnet_id" {
  description = "Bastion subnet ID"
  value       = try(azurerm_subnet.subnets["bastion"].id, null)
}

output "nat_gateway_id" {
  value = azurerm_nat_gateway.this.id
}

output "public_ip_id" {
  value = azurerm_public_ip.nat_gateway.id
}
