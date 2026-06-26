provider "azurerm" {
  features {}
}

# virtual network 
resource "azurerm_virtual_network" "V-net1" {
  name                = "vnet1-hub-prod"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.Secure-Lab-RG.location
  resource_group_name = azurerm_resource_group.Secure-Lab-RG.name
}

# subnet for the V.Net
resource "azurerm_subnet" "subnet1" {
  name                 = "vm-subnet1"
  resource_group_name  = azurerm_resource_group.Secure-Lab-RG.name
  virtual_network_name = azurerm_virtual_network.V-net1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.Secure-Lab-RG.name
  virtual_network_name = azurerm_virtual_network.V-net1.name
  address_prefixes     = ["10.0.3.0/24"]
}

#network interface for the VM
resource "azurerm_network_interface" "secure-VM1-nic" {
  name                = "Lab-VM1-nic"
  location            = azurerm_resource_group.Secure-Lab-RG.location
  resource_group_name = azurerm_resource_group.Secure-Lab-RG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

# The VM
resource "azurerm_windows_virtual_machine" "Secure-VM1" {
  name                = "vm-win-secure"
  resource_group_name = azurerm_resource_group.Secure-Lab-RG.name
  location            = azurerm_resource_group.Secure-Lab-RG.location
  size                = "Standard_D4_v5"
  admin_username      = "adminuser"
  admin_password      = "P@ssw0rd1234"
  network_interface_ids = [
    azurerm_network_interface.secure-VM1-nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2025-Datacenter"
    version   = "latest"
  }
}

# Network Security Group
resource "azurerm_network_security_group" "NSG1" {
  name                = "NetworkSecurityGroup1"
  location            = azurerm_resource_group.Secure-Lab-RG.location
  resource_group_name = azurerm_resource_group.Secure-Lab-RG.name

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
