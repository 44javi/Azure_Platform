package main

import (
  "context"
  "database/sql"
  "fmt"
  "os"
  "log"

  _ "github.com/databricks/databricks-sql-go"
  "github.com/joho/godotenv"
)

func main() {
    // Load environment variables from .env file
    err := godotenv.Load()
    if err != nil {
        log.Println("Warning: Error loading .env file:", err)
    }

    dsn := os.Getenv("DATABRICKS_DSN")
    if dsn == "" {
        log.Fatal("DATABRICKS_DSN is not set in the environment")
    }

    // Connect to Databricks
    db, err := sql.Open("databricks", dsn)
    if err != nil {
        log.Fatal("Failed to connect to Databricks: ", err)
    }
    defer db.Close()

    // Query to show schemas in the catalog
    query := `
    SHOW SCHEMAS IN catalog_cyber_prod;
    `

    rows, err := db.QueryContext(context.Background(), query)
    if err != nil {
        log.Fatal("Query execution failed: ", err)
    }
    defer rows.Close()

    var schemaName sql.NullString
    fmt.Println("Schemas in catalog_cyber_prod:")

    for rows.Next() {
        if err := rows.Scan(&schemaName); err != nil {
            log.Fatal("Failed to scan row: ", err)
        }
        fmt.Printf("Schema: %s\n", schemaName.String)
    }

    if err := rows.Err(); err != nil {
        log.Fatal("Rows iteration error: ", err)
    }
}