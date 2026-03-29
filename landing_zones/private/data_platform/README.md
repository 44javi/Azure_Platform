# Azure Data Platform 

A repository for automating **Azure** and **Databricks** deployments with **Terraform**.

---

## Table of Contents

- [Pre-requisites](#pre-requisites)
- [Deployment Steps](#deployment-steps)
- [Diagrams](#diagrams)
- [Project Structure](#project-structure)
- [Resources Documentation](#resources-documentation)

---

## Pre-requisites

- Create Azure management group
- Set Subscriptions
- Azure CLI - https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
- Databricks CLI - https://docs.databricks.com/en/dev-tools/cli/install.html
- Terraform - https://developer.hashicorp.com/terraform/install

## Deployment Steps

1. Initial Deployment
   - `chmod +x ./.debug.prod.sh`
   - `./.debug.prod.sh plan`
   - `./.debug.prod.sh apply` to deploy the infrastructure
2. Databricks CLI (optional)
   - The Databricks CLI is not required to deploy resources via Terraform, but is useful for interacting directly with the workspace uploading notebooks, running jobs, managing secrets, or debugging
   - Generate a personal access token from the workspace (User Settings → Developer → New Token)
   - Configure the Databricks CLI:
     ```bash
     databricks configure --token
     ```
   - Enter the workspace URL and access token when prompted
   - This creates a `~/.databrickscfg` file that enables authentication

---

## Diagrams

### Azure data lake and Databricks

![Azure resources](assets/azure_resources.png)

### Databricks Architecture

![Databricks Diagram](assets/databricks_workspace.png)

> **Note:** The diagrams are a **high level overview** and don't capture the **all deployed resources**.

---

## Project Structure

```
azure_platform/
├── platform/
│   ├── management/               # Management subscription resources (Log Analytics, etc.)
│   └── connectivity/             # Connectivity subscription resources
│
├── landing_zones/
│   ├── private/
│   │   └── data_platform/        # This landing zone
│   │       ├── env/
│   │       │   ├── dev.tfvars
│   │       │   └── prod.tfvars
│   │       ├── assets/           # Diagram assets
│   │       ├── notebooks/        # Databricks notebooks
│   │       ├── query_app/        # Go application for querying the data platform
│   │       ├── .debug.prod.sh    # Init, backend config, and Terraform runner script
│   │       ├── main.tf           # Orchestrates all modules for this landing zone
│   │       ├── variables.tf
│   │       ├── outputs.tf
│   │       └── versions.tf       # Provider and backend configuration
│   └── public/
│       ├── cloud_resume/
│       └── portfolio/
│
├── modules/                      # Shared reusable Terraform modules
│   ├── network/                  # VNet, subnets, NSGs, NAT gateway
│   ├── storage/                  # ADLS Gen2 data lake
│   ├── dbx_workspace/            # Databricks workspace with VNet injection
│   ├── dbx_resources/            # Workspace-level resources (clusters, catalogs, schemas)
│   ├── security/                 # Key Vault, service principals, security groups
│   ├── monitoring/               # Log Analytics, diagnostic settings
│   ├── compute/                  # Compute resources
│   ├── automation/               # Automation scripts and runbooks
│   ├── service_principal/        # Service principal management
│
└── template.tf                   # Templates for tfvars and debug.sh files
```
