/* required for service map to work */
variable "AADLoginForWindows" {
  description = "Should the VM be include the dependancy agent"
  default     = null
}

resource "azurerm_virtual_machine_extension" "AADLoginForWindows" {
  count                      = var.AADLoginForWindows == null ? 0 : 1
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.VM.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "0.3"
  auto_upgrade_minor_version = true
  depends_on                 = [azurerm_virtual_machine_extension.CustomScriptExtension]
}
