output "hub_vnet_id" {
  description = "Hub VNet resource ID"
  value       = module.hub_vnet.vnet_id
}

output "hub_vnet_name" {
  description = "Hub VNet name"
  value       = module.hub_vnet.vnet_name
}

# output "vpn_gateway_id" {
#   description = "VPN Gateway resource ID"
#   value       = var.enable_vpn_gateway ? azurerm_virtual_network_gateway.vpn[0].id : null
# }

# output "vpn_gateway_public_ip" {
#   description = "VPN Gateway public IP — use this as the server address in your VPN client profile"
#   value       = var.enable_vpn_gateway ? azurerm_public_ip.vpn_gateway[0].ip_address : null
# }

# output "jumpbox_public_ip" {
#   description = "Jumpbox public IP — the WireGuard endpoint in generated client configs (SERVERURL=auto resolves to this)"
#   value       = module.jumpbox.public_ip_addresses["jumpbox"]
# }

# output "jumpbox_private_ip" {
#   description = "Jumpbox private IP inside the hub VNet"
#   value       = module.jumpbox.private_ip_addresses["jumpbox"]
# }

output "dns_resolver_inbound_ip" {
  description = "DNS Private Resolver inbound endpoint IP — VPN clients use this for DNS after re-downloading the VPN profile"
  value       = var.enable_dns_resolver ? azurerm_private_dns_resolver_inbound_endpoint.hub[0].ip_configurations[0].private_ip_address : null
}
