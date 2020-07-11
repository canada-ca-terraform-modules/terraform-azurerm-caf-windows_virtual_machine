output "name" {
  depends_on = [azurerm_windows_virtual_machine.VM[0]]
  value      = azurerm_windows_virtual_machine.VM[0].name
}

output "id" {
  depends_on = [azurerm_windows_virtual_machine.VM[0]]
  value      = azurerm_windows_virtual_machine.VM[0].id
}
output "vm" {
  depends_on = [azurerm_windows_virtual_machine.VM[0]]
  value      = azurerm_windows_virtual_machine.VM[0]
}

output "pip" {
  depends_on = [azurerm_public_ip.VM-EXT-PubIP[0]]
  value      = var.var.public_ip ? azurerm_public_ip.VM-EXT-PubIP[0] : null
}

output "nic" {
  depends_on = [azurerm_network_interface.NIC[0]]
  value      = azurerm_network_interface.NIC[0]
}