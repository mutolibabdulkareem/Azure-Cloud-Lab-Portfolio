output "resource_group_name" {
  value = azurerm_resource_group.secure_lab.name
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.secure_vm1.name
}

output "vm_private_ip" {
  value = azurerm_network_interface.vm1_nic.private_ip_address
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet1.name
}
