terraform {
  required_version = ">= 0.12.1"
}
provider "azurerm" {
  version = ">= 1.32.0"
  features {}
}

locals {
  template_name = "basicwindowsvm"
}

data "azurerm_client_config" "current" {}

module "test-basicvm4" {
  source            = "../."
  env               = "SaTa"
  serverType        = "SWJ"
  userDefinedString = "Test"
  postfix           = "01"
  resource_group    = azurerm_resource_group.test-RG
  location          = azurerm_resource_group.test-RG.location
  subnet            = azurerm_subnet.subnet1
  priority          = "Spot"
  admin_username    = "azureadmin"
  admin_password    = "Ca3425ghdfhb^w5"
  vm_size           = "Standard_D2s_v3"
  license_type      = "Windows_Server"
  tags              = var.tags
}
