# Network module 

# Grabs Tenant Info
data "azurerm_project_config" "current" {}


# Create the Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project}-${var.environment}"
  address_space       = var.vnet_address_space
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.default_tags
}

# Creates the private subnet for VMs
resource "azurerm_subnet" "private" {
  name                            = "snet-private-${var.project}-${var.environment}"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [var.subnet_address_prefixes["private_subnet"]]
  default_outbound_access_enabled = false # Disable default outbound internet access
}

# Creates the public subnet
resource "azurerm_subnet" "public" {
  name                            = "snet-public-${var.project}-${var.environment}"
  resource_group_name             = var.resource_group_name
  virtual_network_name            = azurerm_virtual_network.vnet.name
  address_prefixes                = [var.subnet_address_prefixes["public_subnet"]]
  default_outbound_access_enabled = false # Disable default outbound internet access
}

# NSG for public subnet
resource "azurerm_network_security_group" "public" {
  name                = "nsg-public-${var.project}-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.default_tags

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.trusted_ip_ranges
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-11091"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "11091"
    source_address_prefixes    = var.trusted_ip_ranges
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Kafka-Access"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9021"
    source_address_prefixes    = var.trusted_ip_ranges
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Receiver"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "9080"
    source_address_prefixes    = var.trusted_ip_ranges
    destination_address_prefix = "*"
  }
}


# Associate public NSG with public subnet
resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}


# Creates the NAT Gateway
resource "azurerm_nat_gateway" "this" {
  name                = "ng-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region

  tags = var.default_tags
}

# Creates the Public IP for NAT Gateway
resource "azurerm_public_ip" "nat_gateway" {
  name                = "ng-ip-${var.project}-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.default_tags
}

# Associates the NAT Gateway with the public ip
resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

# Associate NAT Gateway with the public subnet
resource "azurerm_subnet_nat_gateway_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  nat_gateway_id = azurerm_nat_gateway.this.id

  depends_on = [
    azurerm_nat_gateway.this,
    azurerm_subnet.public
  ]
}

# Associate NAT Gateway with the private Subnet
resource "azurerm_subnet_nat_gateway_association" "nat_gateway_subnet_assoc" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.this.id

  depends_on = [
    azurerm_nat_gateway.this,
    azurerm_subnet.private
  ]
}

# Creates the the subnet for Azure Bastion
resource "azurerm_subnet" "bastion" {
  name                 = "snet-bastion${var.project}-${var.environment}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_address_prefixes["bastion_subnet"]]
}

# Network Security group for private subnet
resource "azurerm_network_security_group" "private" {
  name                = "nsg-private-${var.project}-${var.environment}"
  location            = var.region
  resource_group_name = var.resource_group_name

  tags = var.default_tags

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.subnet_address_prefixes["bastion_subnet"] # Restricts to Bastion subnet
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-Kafka-Access"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9021"
    source_address_prefix      = "VirtualNetwork" # Restrict access to VNet or specify IP ranges
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-Viewer"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5000"
    source_address_prefix      = "VirtualNetwork" # Restrict access to VNet 
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-Viewer-2"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5001"
    source_address_prefix      = "VirtualNetwork" # Restrict access to VNet 
    destination_address_prefix = "*"
  }
}

# Link the NSG with the VM Subnet
resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}
