# =============================================================================
# .debug.prod.sh
# =============================================================================

# # set the subscription
# export BACKEND_SUBSCRIPTION_ID="" # MGMT SUB 
# export ARM_SUBSCRIPTION_ID="" # PROJECT SUB

# # set the project / environment
# export TF_VAR_project=""
# export TF_VAR_environment=""

# # set the backend
# export BACKEND_RESOURCE_GROUP=""
# export BACKEND_STORAGE_ACCOUNT=""
# export BACKEND_STORAGE_CONTAINER=""
# export BACKEND_KEY=$TF_VAR_project-$TF_VAR_environment

# rm -rf .terraform .terraform.lock.hcl

# terraform init -upgrade -reconfigure \
#     -backend-config="subscription_id=${BACKEND_SUBSCRIPTION_ID}" \
#     -backend-config="resource_group_name=${BACKEND_RESOURCE_GROUP}" \
#     -backend-config="storage_account_name=${BACKEND_STORAGE_ACCOUNT}" \
#     -backend-config="container_name=${BACKEND_STORAGE_CONTAINER}" \
#     -backend-config="key=${BACKEND_KEY}"

# #terraform force-unlock # add id from error and comment all commands below to unlock

# #terraform providers

# SUBCOMMAND=$1
# case "$SUBCOMMAND" in
#   plan|apply|destroy|refresh)
#     terraform $* -var-file=./env/${TF_VAR_environment}.tfvars
#     ;;
#   *)
#     terraform $*
#     ;;
# esac

# clean up the local environment
#rm -rf .terraform


# chmod +x ./.debug.prod.sh 
# ./.debug.prod.sh apply

# example to rm from state
#./.debug.prod.sh state rm module.backend.azurerm_storage_account.state


# ------------------------------------------------------------------------------------------------------------------------

# =============================================================================
# SET BACKEND
# =============================================================================

# module "backend" {
#   source = "../../modules/storage/backend"

#   project     = var.project
#   environment = var.environment
#   region      = var.region

#   default_tags = {
#     owner       = var.owner
#     environment = var.environment
#     project     = var.project
#     region      = var.region
#     created_by  = var.created_by
#   }
# }

#----------------------------------------------------------------------------------------------------------------------------

# =============================================================================
# TEMPLATE TFVARS
# =============================================================================

# subscription_id = ""

# # Resource Naming
# project      = ""
# environment = ""

# region = ""

# # Default tags
# owner      = "Javier"
# created_by = "Terraform"



# # =============================================================================
# # NETWORK CONFIGURATION
# # =============================================================================
# vnet_address_space = [""]

# # Subnets managed by the network module.
# # To add a new subnet + NSG, add an entry here
# subnets = {
#   public = {
#     address_prefix     = ""
#     attach_nat_gateway = true
#     nsg_rules = [
#       {
#         name                    = "Allow-Receiver"
#         priority                = 1004
#         direction               = "Inbound"
#         access                  = "Allow"
#         protocol                = "*"
#         destination_port_range  = "9080"
#         source_address_prefixes = ["174.65.195.175"]
#       },
#     ]
#   }

#   private = {
#     address_prefix     = "10.44.32.0/19"
#     attach_nat_gateway = true
#     nsg_rules = [
#       {
#         name                   = "Allow-SSH"
#         priority               = 1001
#         direction              = "Inbound"
#         access                 = "Allow"
#         protocol               = "Tcp"
#         destination_port_range = "22"
#         source_address_prefix  = "10.44.64.0/18" # Bastion subnet only
#       }
#     ]
#   }
# }

# # Address prefixes for Databricks-managed subnets (used by the dbx_workspace module only)
# subnet_address_prefixes = {
#   databricks_public_subnet  = ""
#   databricks_private_subnet = ""
# }

# # =============================================================================
# # MONITORING & LOGGING CONFIGURATION
# # =============================================================================
# alert_email = ""
# management_subscription_id  = ""
# log_analytics_workspace_name = ""                                                                                                                 
# log_analytics_resource_group = ""  

# # List of Azure Data Lake logs to enable
# adls_logs =[
#   "StorageWrite"
# ]


# # =============================================================================
# # DATA PLATFORM CONFIGURATION
# # =============================================================================

# # Lists of Data lake containers
# containers    = ["bronze", "silver", "gold", "catalog"]

# # Databricks Unity Catalog schemas
# schemas       = ["bronze", "silver", "gold"]

# # Datalake (ADLS) permissions
# adls_rbac = {
#   data_engineers = {
#     group_name           = "Data_Engineers"
#     role_definition_name = "Storage Blob Data Contributor"
#   }

# #  external_users = {
# #    group_name           = "External_Users"
# #    role_definition_name = "Storage Blob Data Reader"
# #  }
# }

# # Databricks (dbx) workspace permissions (Control Plane)
# dbx_rbac = {
#    data_engineers = {
#     group_name           = "Data_Engineers"
#     role_definition_name = "Reader"
#   }
# }

# dbx_logs = [
#   "clusters",
#   "jobs",
#   "notebook",
#   "dbfs",
#   "secrets",
#   "sqlPermissions",
#   "unityCatalog"
# ]