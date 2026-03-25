## Resources

| Name                                                                                                                                                                                   | Type                                                                                                                     |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ | ----------- |
| [azurerm_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway)                                                                | Creates NAT gateway for outbound internet connectivity                                                                   | resource    |
| [azurerm_nat_gateway_public_ip_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/nat_gateway_public_ip_association)                    | Associates public IP address with NAT gateway                                                                            | resource    |
| [azurerm_network_security_group.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group)                                       | Creates network security group for private subnet                                                                        | resource    |
| [azurerm_network_security_group.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group)                                        | Creates network security group for public subnet                                                                         | resource    |
| [azurerm_public_ip.nat_gateway](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip)                                                             | Creates public IP address for NAT gateway                                                                                | resource    |
| [azurerm_subnet.bastion](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)                                                                       | Creates subnet for bastion host connectivity                                                                             | resource    |
| [azurerm_subnet.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)                                                                       | Creates private subnet for internal resources                                                                            | resource    |
| [azurerm_subnet.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet)                                                                        | Creates public subnet for internet facing resources                                                                      | resource    |
| [azurerm_subnet_nat_gateway_association.nat_gateway_subnet_assoc](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association)      | Associates NAT gateway with private subnet                                                                               | resource    |
| [azurerm_subnet_nat_gateway_association.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_nat_gateway_association)                        | Associates NAT gateway with public subnet                                                                                | resource    |
| [azurerm_subnet_network_security_group_association.private](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association) | Associates network security group with private subnet                                                                    | resource    |
| [azurerm_subnet_network_security_group_association.public](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_network_security_group_association)  | Associates network security group with public subnet                                                                     | resource    |
| [azurerm_virtual_network.vnet](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network)                                                        | Creates the virtual network infrastructure for either the VM or Databricks workspace or both depending on the deployment | resource    |
| [azurerm_project_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/project_config)                                                    | Retrieves metadata for the current Azure project, including tenant ID, project ID, and object ID                         | data source |

## Inputs

| Name                                                                                                   | Description                                        | Type           | Default | Required |
| ------------------------------------------------------------------------------------------------------ | -------------------------------------------------- | -------------- | ------- | :------: |
| <a name="input_project"></a> [project](#input_project)                                                 | project name for resource naming                   | `string`       | n/a     |   yes    |
| <a name="input_default_tags"></a> [default_tags](#input_default_tags)                                  | Default tags to apply to all resources             | `map(string)`  | n/a     |   yes    |
| <a name="input_environment"></a> [environment](#input_environment)                                     | Environment for resources                          | `string`       | n/a     |   yes    |
| <a name="input_region"></a> [region](#input_region)                                                    | Region where resources will be created             | `string`       | n/a     |   yes    |
| <a name="input_resource_group_id"></a> [resource_group_id](#input_resource_group_id)                   | The full resource ID of the resource group         | `string`       | n/a     |   yes    |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name)             | The name of the resource group                     | `string`       | n/a     |   yes    |
| <a name="input_subnet_address_prefixes"></a> [subnet_address_prefixes](#input_subnet_address_prefixes) | A map of address prefixes for each subnet          | `map(string)`  | n/a     |   yes    |
| <a name="input_trusted_ip_ranges"></a> [trusted_ip_ranges](#input_trusted_ip_ranges)                   | List of trusted IP ranges for access to public VMs | `list(string)` | n/a     |   yes    |
| <a name="input_vnet_address_space"></a> [vnet_address_space](#input_vnet_address_space)                | The address space for the virtual network          | `list(string)` | n/a     |   yes    |

## Outputs

| Name                                                                                   | Description |
| -------------------------------------------------------------------------------------- | ----------- |
| <a name="output_bastion_subnet_id"></a> [bastion_subnet_id](#output_bastion_subnet_id) | n/a         |
| <a name="output_nat_gateway_id"></a> [nat_gateway_id](#output_nat_gateway_id)          | n/a         |
| <a name="output_public_ip_id"></a> [public_ip_id](#output_public_ip_id)                | n/a         |
| <a name="output_public_subnet_id"></a> [public_subnet_id](#output_public_subnet_id)    | n/a         |
| <a name="output_subnet_id"></a> [subnet_id](#output_subnet_id)                         | n/a         |
| <a name="output_vnet_id"></a> [vnet_id](#output_vnet_id)                               | n/a         |
| <a name="output_vnet_name"></a> [vnet_name](#output_vnet_name)                         | n/a         |
