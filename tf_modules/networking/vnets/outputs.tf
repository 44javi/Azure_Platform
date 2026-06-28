# vnets module outputs

output "vnet_id" {
  description = "Resource ID of the virtual network. Used for peering, DNS server assignment, and private endpoints."
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the virtual network. Pass to the subnets module as virtual_network_name."
  value       = azurerm_virtual_network.vnet.name
}

# Map of private DNS zone name to its resource ID. Empty when no zones are declared.
output "private_dns_zone_ids" {
  description = "Map of private DNS zone name to resource ID, for wiring private endpoints to zones."
  value       = { for k, v in azurerm_private_dns_zone.zones : k => v.id }
}
