/* required for service map to work */
variable "AADLoginForWindows" {
  description = "Should the VM be include the dependancy agent"
  default     = false
  type = bool
}

resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  count                      = var.AADLoginForWindows == true && var.deploy ? 1 : 0
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.VM[0].id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "0.3"
  auto_upgrade_minor_version = true
  depends_on                 = [
    azurerm_virtual_machine_extension.CustomScriptExtension,
    azurerm_virtual_machine_data_disk_attachment.data_disks
  ]
}
