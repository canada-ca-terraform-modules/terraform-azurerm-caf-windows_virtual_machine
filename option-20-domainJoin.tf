/*
Example of domain to join variable declaration:

domainToJoin = {
  domainName           = "test.com"
  domainUsername       = "azureadmin"
  domainPassword       = "somePassword"
  domainJoinOptions    = 3
  ouPath               = ""
}

*/

variable "domainToJoin" {
  description = "Object containing the parameters for the domain to join"
  type        = any
  default     = null
}

/*

Provide a list of resourced the domain join might depend on. For example... the completion of the ADDS servers
for example.

*/

variable "domain_join_depends_on" {
  type    = any
  default = null
}

resource "azurerm_virtual_machine_extension" "DomainJoinExtension" {
  count = var.domainToJoin != null ? 1 : 0
  name  = "DomainJoinExtension"
  depends_on = [
    var.domain_join_depends_on,
    azurerm_virtual_machine_extension.CustomScriptExtension,
    azurerm_virtual_machine_extension.AADLoginForWindows,
    azurerm_virtual_machine_data_disk_attachment.data_disks
  ]
  virtual_machine_id   = azurerm_windows_virtual_machine.VM.id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = <<SETTINGS
        {  
          "Name": "${var.domainToJoin.domainName}",
          "OUPath": "${var.domainToJoin.ouPath}",
          "User": "${var.domainToJoin.domainName}\\${var.domainToJoin.domainUsername}",
          "Restart": "true",
          "Options": "${var.domainToJoin.domainJoinOptions}"
        }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
          "Password": "${var.domainToJoin.domainPassword}"
        }
  PROTECTED_SETTINGS

  tags = var.tags
}
