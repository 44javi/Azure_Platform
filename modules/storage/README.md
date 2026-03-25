## Resources

| Name                                                                                                                                                  | Description                                                                                      | Type        |
| ----------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ----------- |
| [azurerm_monitor_diagnostic_setting.adls](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) | Enables logs for Azure Data Lake to send to the log analytic workspace                           | resource    |
| [azurerm_private_endpoint.adls](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint)                     | Creates private endpoint for Data Lake access                                                    | resource    |
| [azurerm_role_assignment.data_engineers_datalake](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)    | Assigns roles to data engineers group for the Data Lake                                          | resource    |
| [azurerm_storage_account.adls](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account)                       | Creates Azure Data Lake Storage Gen2 account                                                     | resource    |
| [azurerm_storage_container.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container)                   | Creates storage containers within the Data Lake                                                  | resource    |
| [random_string.this](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/string)                                           | Generates random string for data lake name                                                       | resource    |
| [azuread_group.data_engineers](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/group)                              | Retrieves existing data engineers Azure Entra ID group                                           | data source |
| [azurerm_project_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/project_config)                   | Retrieves metadata for the current Azure project, including tenant ID, project ID, and object ID | data source |

## Inputs

| Name                                                                                       | Description                                | Type           | Required |
| ------------------------------------------------------------------------------------------ | ------------------------------------------ | -------------- | :------: | --- |
| <a name="input_adls_logs"></a> [adls_logs](#input_adls_logs)                               | List of Data Lake logs to enable           | `list(string)` |   `[]`   | no  |
| <a name="input_project"></a> [project](#input_project)                                     | project name for resource naming           | `string`       |   n/a    | yes |
| <a name="input_containers"></a> [containers](#input_containers)                            | Storage containers for data lake           | `list(any)`    |   n/a    | yes |
| <a name="input_default_tags"></a> [default_tags](#input_default_tags)                      | Default tags to apply to all resources     | `map(string)`  |   n/a    | yes |
| <a name="input_environment"></a> [environment](#input_environment)                         | Environment for resources                  | `string`       |   n/a    | yes |
| <a name="input_log_analytics_id"></a> [log_analytics_id](#input_log_analytics_id)          | ID of the Log Analytics workspace          | `string`       |   n/a    | yes |
| <a name="input_region"></a> [region](#input_region)                                        | Region where resources will be created     | `string`       |   n/a    | yes |
| <a name="input_resource_group_id"></a> [resource_group_id](#input_resource_group_id)       | The full resource ID of the resource group | `string`       |   n/a    | yes |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name) | The name of the resource group             | `string`       |   n/a    | yes |
| <a name="input_subnet_id"></a> [subnet_id](#input_subnet_id)                               | Private subnet id                          | `string`       |   n/a    | yes |
| <a name="input_vnet_id"></a> [vnet_id](#input_vnet_id)                                     | Hub virtual network id                     | `string`       |   n/a    | yes |
| <a name="input_vnet_name"></a> [vnet_name](#input_vnet_name)                               | Name of the virtual network                | `string`       |   n/a    | yes |

## Outputs

| Name                                                                                         | Description                                               |
| -------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| <a name="output_datalake_connection"></a> [datalake_connection](#output_datalake_connection) | The primary connection string for the storage account     |
| <a name="output_datalake_endpoint"></a> [datalake_endpoint](#output_datalake_endpoint)       | The primary Blob service endpoint for the storage account |
| <a name="output_datalake_id"></a> [datalake_id](#output_datalake_id)                         | The resource ID of the Azure Data Lake Storage account    |
| <a name="output_datalake_name"></a> [datalake_name](#output_datalake_name)                   | The name of the Azure Data Lake Storage account           |
