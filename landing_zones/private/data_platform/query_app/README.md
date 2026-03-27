# Databricks SQL Connector
A Go application that connects to a Databricks SQL Warehouse to execute queries.

---

## Prerequisites
- **Go 1.20+**
- **Databricks workspace with a configured SQL Warehouse**
- **SQL Warehouse connection details (token, workspace URL, warehouse ID)**

---

## Installation
1. **Clone the repository**

2. **Initialize Go module and install dependencies:**
```bash
go mod init sql_warehouse
go get github.com/databricks/databricks-sql-go
go get github.com/joho/godotenv
```

## Configuration
Create a `.env` file in your project directory with the Databricks connection string:
``` ini
DATABRICKS_DSN="token:<your-access-token>@<your-workspace>.azuredatabricks.net:443/sql/1.0/warehouses/<warehouse-id>"
```

> **Note:** The connection string should be stored in Azure Key Vault

## Usage
``` bash
go run main.go
```
