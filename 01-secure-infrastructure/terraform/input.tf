# Create a resource group
resource "azurerm_resource_group" "example" {
  name     = "Deployment-resources"
  location = "West Europe"
}

#
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}
