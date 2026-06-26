provider "azurerm" {
  features {}
}

# virtual network 
resource "azurerm_virtual_network" "example" {
  name                = "vnet-hub-prod"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# subnet for the V.Net
resource "azurerm_subnet" "example" {
  name                 = "snet-vms"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Network Security Groupz
resource "azurerm_network_security_group" "example" {
  name                = "NetworkSecurityGroup1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "AllowRDP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "196.6.205.169"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Production"
  }
}
