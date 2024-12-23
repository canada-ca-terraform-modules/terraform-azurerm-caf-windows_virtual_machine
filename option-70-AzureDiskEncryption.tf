/*
Example:

encryptDisks = {
  KeyVaultResourceId = azurerm_key_vault.test-keyvault.id
  KeyVaultURL        = azurerm_key_vault.test-keyvault.vault_uri
}

*/

variable "encryptDisks" {
  description = "Should the VM disks be encrypted. See option-30-AzureDiskEncryption.tf file for example"
  type = object({
    KeyVaultResourceId = string
    KeyVaultURL        = string
  })
  default = null
}

resource "azurerm_virtual_machine_extension" "AzureDiskEncryption" {

  count = var.encryptDisks != null ? 1 : 0
  name  = "AzureDiskEncryption"
  depends_on = [
    azurerm_virtual_machine_extension.CustomScriptExtension,
    azurerm_virtual_machine_extension.DomainJoinExtension,
    azurerm_virtual_machine_extension.AADLoginForWindows,
    azurerm_virtual_machine_extension.DAAgentForWindows,
    azurerm_virtual_machine_extension.MicrosoftMonitoringAgent,
    azurerm_virtual_machine_extension.IaaSAntimalware,
    azurerm_resource_group_template_deployment.autoshutdown,
    azurerm_virtual_machine_data_disk_attachment.data_disks
  ]
  virtual_machine_id         = azurerm_windows_virtual_machine.VM.id
  publisher                  = "Microsoft.Azure.Security"
  type                       = "AzureDiskEncryption"
  type_handler_version       = "2.2"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
        {  
          "EncryptionOperation": "EnableEncryption",
          "KeyVaultResourceId": "${var.encryptDisks.KeyVaultResourceId}",
          "KeyVaultURL": "${var.encryptDisks.KeyVaultURL}",
          "KeyEncryptionAlgorithm": "RSA-OAEP",
          "VolumeType": "All",
          "ResizeOSDisk": false
        }
  SETTINGS

  tags = var.tags
}
