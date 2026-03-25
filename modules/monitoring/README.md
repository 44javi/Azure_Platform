## Resources

| Name                                                                                                                                            | Description                                                  | Type     |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | -------- |
| [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | Creates Log Analytics workspace for monitoring and logging   | resource |
| [azurerm_monitor_action_group.alerts](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_action_group)     | Creates action group for monitoring alerts and notifications | resource |

## Inputs

| Name                                                                                       | Description                                | Type          | Required |
| ------------------------------------------------------------------------------------------ | ------------------------------------------ | ------------- | :------: | --- |
| <a name="input_alert_email"></a> [alert_email](#input_alert_email)                         | Email used for monitoring alerts           | `string`      |   n/a    | yes |
| <a name="input_project"></a> [project](#input_project)                                     | project name for resource naming           | `string`      |   n/a    | yes |
| <a name="input_default_tags"></a> [default_tags](#input_default_tags)                      | Default tags to apply to all resources     | `map(string)` |   n/a    | yes |
| <a name="input_environment"></a> [environment](#input_environment)                         | Environment for resources                  | `string`      |   n/a    | yes |
| <a name="input_region"></a> [region](#input_region)                                        | Region where resources will be created     | `string`      |   n/a    | yes |
| <a name="input_resource_group_id"></a> [resource_group_id](#input_resource_group_id)       | The full resource ID of the resource group | `string`      |   n/a    | yes |
| <a name="input_resource_group_name"></a> [resource_group_name](#input_resource_group_name) | The name of the resource group             | `string`      |   n/a    | yes |

## Outputs

| Name                                                                                      | Description |
| ----------------------------------------------------------------------------------------- | ----------- |
| <a name="output_log_analytics_id"></a> [log_analytics_id](#output_log_analytics_id)       | n/a         |
| <a name="output_log_analytics_name"></a> [log_analytics_name](#output_log_analytics_name) | n/a         |
