## Resources

| Name                                                                                                                                               | Description                                                                                      | Type        |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ----------- |
| [azurerm_key_vault.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault)                                | Creates Azure Key Vault for secrets, keys and certificates                                       | resource    |
| [azurerm_role_assignment.data_engineers_keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | Assigns roles to data engineers group for Key Vault access                                       | resource    |
| [azuread_group.data_engineers](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group)                           | Retrieves existing data engineers Azure Entra ID group                                           | data source |
| [azurerm_project_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/project_config)                | Retrieves metadata for the current Azure project, including tenant ID, project ID, and object ID | data source |

## Inputs

| Name                                                                                       | Description                    | Type          | Default | Required |
| ------------------------------------------------------------------------------------------ | ------------------------------ | ------------- | ------- | :------: |
| <a name="input_project"></a> [project](#input_project)                                     | project name                   | `string`      | n/a     |   yes    |
| <a name="input_default_tags"></a> [default_tags](#input_default_tags)                      | Default tags for resources     | `map(string)` | n/a     |   yes    |
| <a name="input_environment"></a> [environment](#input_environment)                         | Unique environment for naming  | `string`      | n/a     |   yes    |
| <a name="input_region"></a> [region](#input_region)                                        | Region for deployment          | `string`      | n/a     |   yes    |
| <a name="input_resource_group_id"></a> [resource_group_id](#input_resource_group_id)       | The ID of the resource group   | `string`      | n/a     |   yes    |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name) | The name of the resource group | `string`      | n/a     |   yes    |

## Outputs

| Name                                                                                                                 | Description                                    |
| -------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------- |
| <a name="output_data_engineers_display_name"></a> [data_engineers_display_name](#output_data_engineers_display_name) | The display name of the Data Engineers group   |
| <a name="output_data_engineers_group_id"></a> [data_engineers_group_id](#output_data_engineers_group_id)             | Object ID of the Data Engineers security group |
| <a name="output_tenant_id"></a> [tenant_id](#output_tenant_id)                                                       | n/a                                            |
