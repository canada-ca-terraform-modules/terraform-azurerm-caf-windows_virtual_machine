/*
Example:

monitoringAgent = {
  log_analytics_workspace_name                = "somename"
  log_analytics_workspace_resource_group_name = "someRGName"
}

*/

variable "monitoringAgent" {
  description = "Should the VM be monitored"
  default     = null
}

resource "azurerm_virtual_machine_extension" "MicrosoftMonitoringAgent" {

  count                      = var.monitoringAgent != null && var.deploy ? 1 : 0
  name                       = "MicrosoftMonitoringAgent"
  depends_on                 = [
    azurerm_virtual_machine_extension.CustomScriptExtension,
    azurerm_virtual_machine_extension.DomainJoinExtension, 
    azurerm_virtual_machine_extension.AADLoginForWindows,
    azurerm_virtual_machine_extension.DAAgentForWindows,
    azurerm_virtual_machine_data_disk_attachment.data_disks
  ]
  virtual_machine_id         = azurerm_windows_virtual_machine.VM[0].id
  publisher                  = "Microsoft.EnterpriseCloud.Monitoring"
  type                       = "MicrosoftMonitoringAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true

  settings = <<SETTINGS
        {  
          "workspaceId": "${var.monitoringAgent.workspace_id}"
        }
  SETTINGS

  protected_settings = <<PROTECTED_SETTINGS
        {
          "workspaceKey": "${var.monitoringAgent.primary_shared_key}"
        }
  PROTECTED_SETTINGS
}
