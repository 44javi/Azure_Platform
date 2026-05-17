output "hub_vnet_id" {
  description = "Hub VNet resource ID"
  value       = module.network_connectivity.vnet_id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = module.network_connectivity.vnet_name
}

output "vpn_gateway_id" {
  description = "VPN Gateway resource ID"
  value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
}

output "vpn_gateway_public_ip" {
  description = "VPN Gateway public IP — use this as the server address in your VPN client profile"
  value       = var.enable_vpn_gateway ? azurerm_public_ip.vpn_gateway[0].ip_address : null
}
