# Jumpbox VM in the hub VNet running a WireGuard VPN server container — the
# low-cost VPN entry point into the hub and peered spokes. Clients get DNS via
# the hub DNS Private Resolver so privatelink FQDNs resolve to private IPs.
# Entra ID SSH login is the management access path (az ssh vm); a generated
# break-glass SSH private key is stored in the central management Key Vault.
#
# Requires a "jumpbox" subnet in var.subnets with UDP 51820 open. Set
# jumpbox_admin_login_principal_ids to grant Entra ID login.

locals {
  # CIDRs routed through the tunnel and written into generated peer configs
  jumpbox_vpn_allowed_cidrs = concat(var.vnet_address_space, var.vpn_vnet_spoke_cidrs)

  jumpbox_cloud_init = templatefile("${path.module}/cloud-init/jumpbox.yaml.tftpl", {
    peers           = join(",", var.jumpbox_vpn_peers)
    peer_dns        = var.enable_dns_resolver ? azurerm_private_dns_resolver_inbound_endpoint.hub[0].ip_configurations[0].private_ip_address : "auto"
    allowed_ips     = join(",", local.jumpbox_vpn_allowed_cidrs)
    internal_subnet = var.jumpbox_vpn_internal_subnet
  })
}

module "jumpbox" {
  source = "git::https://gitlab.com/cybernetic-nimbus-group/cloud/azure-platform.git//tf_modules/compute/linux_vms?ref=linux_vms-v2.0.0"

  resource_group_name = azurerm_resource_group.main.name
  project             = var.project
  environment         = var.environment
  region              = var.region
  key_vault_id        = data.azurerm_key_vault.management.id
  default_tags        = local.default_tags

  virtual_machines = {
    jumpbox = {
      subnet_id = module.hub_subnets.subnet_ids["jumpbox"]

      # Entra ID user/group object IDs allowed to log in with sudo via `az ssh vm`
      admin_login_principal_ids = var.jumpbox_admin_login_principal_ids

      # WireGuard endpoint for laptops / router
      create_public_ip = true
      # Forward tunnel traffic into the VNet (NAT/masquerade happens in the container)
      enable_ip_forwarding = true
      # Docker + WireGuard server container; changing this forces VM replacement
      custom_data = local.jumpbox_cloud_init

      # ---- Optional overrides (defaults shown) ----
      # size               = "Standard_D2als_v7"
      # admin_username     = "azureadmin"
      # zone               = "1"               # default: no zone pinning
      # private_ip_address = "10.79.250.10"    # default: dynamic allocation
      # entra_id_login     = true              # false skips the AADSSHLoginForLinux extension
      # user_login_principal_ids = []          # Entra ID login without sudo

      # os_disk = {
      #   storage_account_type = "StandardSSD_LRS"
      #   disk_size_gb         = 64
      # }

      # source_image_reference = {             # default: Ubuntu 24.04 LTS
      #   publisher = "Canonical"
      #   offer     = "ubuntu-24_04-lts"
      #   sku       = "server"
      #   version   = "latest"
      # }
    }
  }
}
