# Portfolio-Website
A personal portfolio website showcasing projects, built with modern cloud native technologies.

**Live Site**: [portfolioforjavier.com](https://portfolioforjavier.com)

## Table of Contents
* Overview
* Pre-requisites
* Deployment Steps


## Overview
This repository contains the infrastructure code and frontend files for my personal portfolio website. It uses containerization (Docker), infrastructure as code (Terraform), and Azure.

## Pre-requisites
* Docker    - [Installation Guide](https://docs.docker.com/get-docker/)
* Azure CLI - [Installation Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* Terraform - [Installation Guide](https://developer.hashicorp.com/terraform/install)
* Azure Subscription
* Custom domain name 

## Deployment Steps

1. **Infrastructure Deployment**
  * Set up shared infrastructure repository first 
  * `terraform init`
  * `terraform plan` 
  * `terraform apply` 

2. **Application Deployment**
  * Build Docker image: `docker build -t <username>/portfolio:latest .`
  * Push to Docker Hub: `docker push <username>/portfolio:latest`

3. **Custom Domain Configuration**
  * After applying Terraform, you'll receive the custom domain verification ID in the terminal
  * Create DNS records in Cloudflare:
    * A record: `@ → [Container App Environment IP]`
    * CNAME record: `www → [Container App FQDN]`
    * TXT record: `asuid → [Custom Domain Verification ID]`
    * TXT record: `asuid.www → [Custom Domain Verification ID]`
    * Set records to DNS-only mode initially (gray cloud)
  * Wait for certificate provisioning (status: "Secured")
  * Enable Cloudflare proxying (orange cloud)
