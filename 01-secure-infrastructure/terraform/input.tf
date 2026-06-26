# Create a resource group
resource "azurerm_resource_group" "Secure-Lab-RG" {
  name     = "Secure-Lab"
  location = "West Europe"
}

#
resource "azurerm_subnet_network_security_group_association" "bastion_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.bastion_subnet.id
  network_security_group_id = azurerm_network_security_group.NSG1.id
}
