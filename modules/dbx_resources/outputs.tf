# Output the warehouse ID and JDBC URL for reference
output "sql_warehouse_id" {
  value = databricks_sql_endpoint.sql_warehouse.id
}

output "sql_warehouse_jdbc_url" {
  value = databricks_sql_endpoint.sql_warehouse.jdbc_url
}

output "sql_warehouse_odbc_params" {
  value = databricks_sql_endpoint.sql_warehouse.odbc_params
}