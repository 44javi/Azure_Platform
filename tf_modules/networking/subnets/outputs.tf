# subnets module outputs

# Map of subnet key to subnet ID — the preferred reference: module.subnets.subnet_ids["private"]
output "subnet_ids" {
  description = "Map of subnet key to subnet ID for all subnets managed by this module."
  value       = { for k, v in azurerm_subnet.subnets : k => v.id }
}

# Map of subnet key to NSG ID — only includes subnets that declared nsg_rules.
output "nsg_ids" {
  description = "Map of subnet key to network security group ID."
  value       = { for k, v in azurerm_network_security_group.subnets : k => v.id }
}

output "nat_gateway_id" {
  description = "Resource ID of the NAT gateway, or null when no subnet opted in."
  value       = one(azurerm_nat_gateway.this[*].id)
}
