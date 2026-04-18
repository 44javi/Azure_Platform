# Create Data Engineers Security Group
resource "azuread_group" "data_engineers" {
  display_name     = "Data_Engineers"
  security_enabled = true
  description      = "Group for data related access"
}

# Create Test team Security Group
resource "azuread_group" "test_team" {
  display_name     = "Test_Team"
  security_enabled = true
  description      = "Group for the test team to have access to Azure resources"
}

# Create External Security Group
resource "azuread_group" "External_Users" {
  display_name     = "External_Users"
  security_enabled = true
  description      = "Group for guests to have access to Azure resources"
}

# Create metastore admin
resource "azuread_group" "dbx_metastore_admins" {
  display_name     = "DBX_Metastore_Admins"
  security_enabled = true
  description      = "Group for users and principals to have access to the metastore"
}

resource "azuread_group" "dbx_account_admins" {
  display_name     = "DBX_Account_Admins"
  security_enabled = true
  description      = "Group for users and principals to have access to the Databricks account console"
}