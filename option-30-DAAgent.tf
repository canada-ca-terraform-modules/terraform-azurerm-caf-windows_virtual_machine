/* required for service map to work */
variable "dependancyAgent" {
  description = "Should the VM be include the dependancy agent"
  default     = false
  type = bool
}

resource "azurerm_virtual_machine_extension" "DAAgentForWindows" {
  count                      = var.dependancyAgent == true && var.deploy ? 1 : 0
  name                       = "DAAgentForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.VM[0].id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentWindows"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
  depends_on                 = [
    azurerm_virtual_machine_extension.CustomScriptExtension,
    azurerm_virtual_machine_extension.DomainJoinExtension, 
    azurerm_virtual_machine_extension.AADLoginForWindows,
    azurerm_virtual_machine_data_disk_attachment.data_disks
  ]
}
