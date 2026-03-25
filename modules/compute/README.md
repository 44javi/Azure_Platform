## Resources

| Name                                                                                                                                        | Description                              | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------- | -------- |
| [azapi_resource.ssh_public_key](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource)                         | Creates SSH public key resource in Azure | resource |
| [azapi_resource_action.ssh_public_key_gen](https://registry.terraform.io/providers/azure/azapi/latest/docs/resources/resource_action)       | Generates SSH public key pair            | resource |
| [azurerm_linux_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine) | Creates the Linux virtual machine        | resource |
| [azurerm_network_interface.vm_nic](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface)       | Creates network interface for the VM     | resource |
| [azurerm_public_ip.vm_public_ip](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)                 | Creates public IP address for the VM     | resource |
| [local_file.private_key](https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file)                                | Saves SSH private key locally            | resource |
| [random_pet.ssh_key_name](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/pet)                               | Generates random name for SSH key        | resource |
| [random_string.vm_name_suffix](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string)                       | Generates random suffix for the VM       | resource |

## Inputs

| Name                                                                                       | Description                                | Type          | Default | Required |
| ------------------------------------------------------------------------------------------ | ------------------------------------------ | ------------- | ------- | :------: |
| <a name="input_project"></a> [project](#input_project)                                     | project name for resource naming           | `string`      | n/a     |   yes    |
| <a name="input_default_tags"></a> [default_tags](#input_default_tags)                      | Default tags to apply to all resources     | `map(string)` | n/a     |   yes    |
| <a name="input_environment"></a> [environment](#input_environment)                         | Numerical identifier for resources         | `string`      | n/a     |   yes    |
| <a name="input_public_subnet_id"></a> [public_subnet_id](#input_public_subnet_id)          | Public subnet id                           | `string`      | n/a     |   yes    |
| <a name="input_region"></a> [region](#input_region)                                        | Region where resources will be created     | `string`      | n/a     |   yes    |
| <a name="input_resource_group_id"></a> [resource_group_id](#input_resource_group_id)       | The full resource ID of the resource group | `string`      | n/a     |   yes    |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name) | The name of the resource group             | `string`      | n/a     |   yes    |
| <a name="input_subnet_id"></a> [subnet_id](#input_subnet_id)                               | Private subnet id                          | `string`      | n/a     |   yes    |
| <a name="input_username"></a> [username](#input_username)                                  | Username for accounts                      | `string`      | n/a     |   yes    |
| <a name="input_vm_private_ip"></a> [vm_private_ip](#input_vm_private_ip)                   | Static private IP address for the VM       | `string`      | n/a     |   yes    |
| <a name="input_vnet_id"></a> [vnet_id](#input_vnet_id)                                     | Hub virtual network id                     | `string`      | n/a     |   yes    |
| <a name="input_vnet_name"></a> [vnet_name](#input_vnet_name)                               | Name of the virtual network                | `string`      | n/a     |   yes    |

## Outputs

No outputs.
