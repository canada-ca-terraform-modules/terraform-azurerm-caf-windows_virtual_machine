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

  count                      = var.monitoringAgent == null ? 0 : 1
  name                       = "MicrosoftMonitoringAgent"
  depends_on                 = [azurerm_virtual_machine_extension.DAAgentForWindows]
  virtual_machine_id         = azurerm_windows_virtual_machine.VM.id
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
