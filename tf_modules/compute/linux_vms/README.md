# Linux VMs Module

Creates Linux virtual machines with Entra ID SSH login as the primary access
path. Password authentication is disabled. Because Azure requires an admin SSH
key at provision time, the module generates a per-VM keypair and stores the
private key in Key Vault as a break-glass credential.

Per VM the module creates:

- NIC (optionally with a static private IP and/or a Standard static public IP)
- SSH keypair, with the private key stored as a Key Vault secret
- Linux VM with system-assigned managed identity and managed boot diagnostics
- `AADSSHLoginForLinux` extension (unless `entra_id_login = false`)
- `Virtual Machine Administrator Login` / `Virtual Machine User Login` role
  assignments scoped to the VM

## Requirements

The root module must configure these providers:

```hcl
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
}
```

The identity running Terraform needs permission to create the VM resources,
write secrets to the target Key Vault, and create role assignments on the VMs
(for example `Role Based Access Control Administrator` or `Owner` at the
resource group scope) when login principal IDs are set.

## Usage

```hcl
module "linux_vms" {
  source = "git::https://<scm-host>/<group>/azure-platform.git//tf_modules/compute/linux_vms?ref=linux_vms-v1.0.0"

  project             = var.project
  environment         = var.environment
  region              = var.region
  resource_group_name = azurerm_resource_group.main.name
  key_vault_id        = azurerm_key_vault.main.id
  default_tags        = var.default_tags

  virtual_machines = {
    app = {
      subnet_id                 = module.subnets.subnet_ids["app"]
      size                      = "Standard_D2s_v5"
      admin_login_principal_ids = [var.platform_admins_group_object_id]
    }
    jump = {
      subnet_id                = module.subnets.subnet_ids["jump"]
      private_ip_address       = "10.10.1.10"
      user_login_principal_ids = [var.developers_group_object_id]
    }
  }
}
```

## Entra ID login

Users covered by a login role assignment sign in with their Entra identity,
no SSH key distribution needed:

```bash
az ssh vm --resource-group <rg> --name vm-app-<project>-<environment>
```

Assign `admin_login_principal_ids` (sudo) or `user_login_principal_ids`
(no sudo) with user or group object IDs. Conditional Access and MFA policies
apply to these logins.

## Break-glass SSH key

For each VM the private key is stored in Key Vault as
`vm-<key>-<project>-<environment>-ssh-private-key`. Use it only when Entra ID
login is unavailable:

```bash
az keyvault secret show --vault-name <vault> \
  --name vm-app-<project>-<environment>-ssh-private-key \
  --query value -o tsv > key.pem && chmod 600 key.pem
ssh -i key.pem azureadmin@<private-ip>
```

Key Vault does not rotate this key automatically. To rotate, replace the
keypair; Terraform updates the VM's authorized key and writes a new secret
version:

```bash
terraform apply -replace='module.linux_vms.tls_private_key.vms["app"]'
```

## Inputs

| Name | Required | Description |
| --- | --- | --- |
| `resource_group_name` | yes | Resource group for all VM resources. |
| `region` | yes | Azure region. |
| `project` | yes | Name segment used for resource naming. |
| `environment` | yes | Environment name segment used for naming. |
| `key_vault_id` | yes | Key Vault that stores the break-glass SSH private keys. |
| `default_tags` | no | Tags applied to all resources. |
| `virtual_machines` | no | Map of VMs to create, keyed by short name. See below. |

Per-VM object (all optional except `subnet_id`):

| Field | Default | Description |
| --- | --- | --- |
| `subnet_id` | - | Subnet for the NIC. |
| `size` | `Standard_B2s` | VM size. |
| `admin_username` | `azureadmin` | Admin user for the break-glass SSH key. |
| `zone` | none | Availability zone for the VM and its public IP. |
| `private_ip_address` | dynamic | Static private IP when set. |
| `create_public_ip` | `false` | Attach a Standard static public IP. |
| `enable_ip_forwarding` | `false` | NIC-level IP forwarding, for VMs that route traffic (e.g. VPN server). |
| `custom_data` | none | Cloud-init user data (plain text). Changing it forces VM replacement. |
| `os_disk` | `StandardSSD_LRS`, 64 GB | `storage_account_type` and `disk_size_gb`. |
| `source_image_reference` | Ubuntu 24.04 LTS | `publisher`/`offer`/`sku`/`version`. |
| `entra_id_login` | `true` | Install the `AADSSHLoginForLinux` extension. |
| `admin_login_principal_ids` | `[]` | Object IDs granted `Virtual Machine Administrator Login` on the VM. |
| `user_login_principal_ids` | `[]` | Object IDs granted `Virtual Machine User Login` on the VM. |

## Outputs

| Name | Description |
| --- | --- |
| `vm_ids` / `vm_names` | Map of VM key to resource ID / name. |
| `principal_ids` | Map of VM key to system-assigned managed identity principal ID. |
| `private_ip_addresses` | Map of VM key to primary private IP. |
| `public_ip_addresses` | Map of VM key to public IP (only VMs with `create_public_ip = true`). |
| `admin_usernames` | Map of VM key to admin username. |
| `ssh_private_key_secret_names` / `ssh_private_key_secret_ids` | Key Vault secret name / ID of the break-glass private key. |
| `ssh_public_keys` | Map of VM key to OpenSSH public key. |
