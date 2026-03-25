## Resources

| Name                                                                                                                                                     | Type                                                                                                                    |
| -------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------- | -------- |
| [azurerm_databricks_access_connector.unity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/databricks_access_connector) | Creates Databricks access connector for Unity Catalog to access the data lake                                           | resource |
| [azurerm_role_assignment.unity_eventsubscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)       | Required event subscription role role for Unity Catalog                                                                 | resource |
| [azurerm_role_assignment.unity_queue](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                   | Required queue access role for Unity Catalog                                                                            | resource |
| [azurerm_role_assignment.unity_storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                 | Required role for Unity Catalog connector to access data lake                                                           | resource |
| [azurerm_role_assignment.unity_storage_account](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)         | Assigns roles for Unity Catalog connnector to access data lake                                                          | resource |
| [databricks_catalog.main](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/catalog)                                   | Creates catalog for the project in Databricks workspace                                                                 | resource |
| [databricks_external_location.this](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/external_location)               | Creates external locations for Unity Catalog and schemas that point to storage containers in the data lake              | resource |
| [databricks_schema.schemas](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/schema)                                  | Creates the schemas within the Unity Catalog                                                                            | resource |
| [databricks_storage_credential.unity](https://registry.terraform.io/providers/databricks/databricks/latest/docs/resources/storage_credential)            | Creates storage credentials for Unity Catalog authentication to the data lake with the identity of the access connector | resource |

## Inputs

| Name                                                                                       | Description                                            | Type        | Default | Required |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------ | ----------- | ------- | :------: |
| <a name="input_project"></a> [project](#input_project)                                     | project name for resource naming                       | `string`    | n/a     |   yes    |
| <a name="input_containers"></a> [containers](#input_containers)                            | Storage containers in the data lake                    | `list(any)` | n/a     |   yes    |
| <a name="input_datalake_id"></a> [datalake_id](#input_datalake_id)                         | The resource ID of the Azure Data Lake Storage account | `string`    | n/a     |   yes    |
| <a name="input_datalake_name"></a> [datalake_name](#input_datalake_name)                   | The name of the Azure Data Lake Storage account        | `string`    | n/a     |   yes    |
| <a name="input_environment"></a> [environment](#input_environment)                         | Environment for resource naming                        | `string`    | n/a     |   yes    |
| <a name="input_region"></a> [region](#input_region)                                        | The region where resources will be created             | `string`    | n/a     |   yes    |
| <a name="input_resource_group_id"></a> [resource_group_id](#input_resource_group_id)       | The ID of the resource group                           | `string`    | n/a     |   yes    |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name) | The name of the resource group                         | `string`    | n/a     |   yes    |
| <a name="input_schemas"></a> [schemas](#input_schemas)                                     | Schema names for dbx catalog                           | `list(any)` | n/a     |   yes    |
| <a name="input_workspace_id"></a> [workspace_id](#input_workspace_id)                      | The ID of the Databricks workspace                     | `string`    | n/a     |   yes    |

## Outputs

No outputs.
