# Resource Naming
project      = "connectivity"
environment = "prod"

region = "westus2"

alert_email = ""

# Default tags
owner      = "Javier"
created_by = "Terraform"

vnet_address_space = ["10.79.0.0/16"]

# Private DNS zones — add a new line here to create a zone; spokes look them up via data source
private_dns_zones = [
  # "privatelink.services.ai.azure.com", # Foundry account
  # "privatelink.openai.azure.com", # Foundry account
  # "privatelink.cognitiveservices.azure.com", # Foundry account
  # "privatelink.search.windows.net", # Search service
  "privatelink.blob.core.windows.net", # blob storage
  "privatelink.vaultcore.azure.net",
  # "privatelink.azurewebsites.net",
  # "privatelink.documents.azure.com",  # Cosmos DB
  # "privatelink.api.azureml.ms",
  # "privatelink.notebooks.azure.net",
  "privatelink.azuredatabricks.net", # Databricks front-end/back-end + browser auth
  "privatelink.dfs.core.windows.net" # ADLS Gen2 (Databricks data plane)
]

# Subnets managed by the network module.
# To add a new subnet + NSG, add an entry here.
# (landing_zones/public/cyber_parts/infra). Only hub-specific subnets belong here.
subnets = {
  # Azure requires this subnet to be named exactly "GatewaySubnet" — no NSG or route table allowed.
  GatewaySubnet = {
    address_prefix           = "10.79.255.0/26"
    name_override            = "GatewaySubnet"
    disable_default_outbound = false
    nsg_rules                = []
  }

  # Dedicated subnet for the Azure DNS Private Resolver inbound endpoint.
  # Requires delegation to Microsoft.Network/dnsResolvers — no NSG allowed.
  dns_resolver = {
    address_prefix           = "10.79.254.0/28"
    name_override            = "snet-dnsresolver-prod"
    disable_default_outbound = false
    nsg_rules                = []
    delegation = {
      service_name = "Microsoft.Network/dnsResolvers"
      actions      = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }

  # Jumpbox subnet — hosts the WireGuard VPN server. Only the WireGuard UDP
  # port is open to the internet. SSH rides inside the tunnel (never traverses the NSG), so port
  # 22 stays closed. Default outbound stays enabled: Entra ID SSH login and
  # SERVERURL=auto need outbound HTTPS.
  jumpbox = {
    address_prefix           = "10.79.250.0/28"
    disable_default_outbound = false
    nsg_rules = [
      {
        name                   = "Allow-WireGuard"
        priority               = 1001
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Udp"
        destination_port_range = "51820"
        source_address_prefix  = "Internet"
      },
    ]
  }

#   public = {
#     address_prefix     = "10.79.0.0/19"
#     attach_nat_gateway = true
#     nsg_rules = [
#       {
#         name                    = "Allow-SSH"
#         priority                = 1001
#         direction               = "Inbound"
#         access                  = "Allow"
#         protocol                = "Tcp"
#         destination_port_range  = "22"
#         source_address_prefixes = ["174.65.195.175"]
#       },
#     ]
#   }

#   private = {
#     address_prefix     = "10.79.32.0/19"
#     attach_nat_gateway = true
#     nsg_rules = [
#       {
#         name                   = "Allow-SSH"
#         priority               = 1001
#         direction              = "Inbound"
#         access                 = "Allow"
#         protocol               = "Tcp"
#         destination_port_range = "22"
#         source_address_prefix  = "10.44.64.0/18" # Bastion subnet only
#       },
#     ]
#   }
}

# ---- DNS Private Resolver ----
enable_dns_resolver = true

# # ---- VPN Gateway (Point-to-Site) ----
# enable_vpn_gateway = true

# # Defaults that work for most setups — override only if needed:
# vpn_gateway_sku         = "VpnGw1AZ"            # Max 128 SSTP / 250 IKEv2 P2S sessions
# vpn_client_protocols    = ["OpenVPN"]          # SSTP retired Mar 31 2026; IkeV2 is the Basic SKU replacement
# vpn_auth_types          = ["AAD"]    # Certificate auth works with IkeV2; use ["AAD"] + OpenVPN for larger deployments
# # vpn_client_address_pool = "172.16.201.0/24"  # IPs assigned to VPN clients

# Central management Key Vault — jumpbox break-glass SSH key, and root CA when
# Certificate VPN auth is enabled.
mg_kv_name = "kv-management-prod-5209"
mg_kv_rg   = "rg-management-prod"

# ---- Jumpbox / WireGuard VPN ----
# Usually empty: org VM admin groups get sudo login (Virtual Machine
# Administrator Login) at the management group scope in platform/management
# and inherit it on this VM. Only list principals that need sudo on the
# jumpbox alone, on top of that.
# jumpbox_admin_login_principal_ids = ["<user-or-group-object-id>"]

# One client config is generated per peer name (alphanumeric only).
jumpbox_vpn_peers = ["laptop", "router"]

# Spoke VNet CIDRs routed through the tunnel — extend as spokes are added.
vpn_vnet_spoke_cidrs = ["10.80.0.0/16"]