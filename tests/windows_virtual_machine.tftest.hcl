# tests/windows_virtual_machine.tftest.hcl
# Functional plan-only tests for the azurerm_windows_virtual_machine module,
# targeting azurerm provider ~> 5.0.

mock_provider "azurerm" {}

variables {
  env               = "Dev"
  serverType        = "SRV"
  userDefinedString = "test"
  admin_username    = "azureadmin"
  admin_password    = "P@ssw0rd12345!"
  vm_size           = "Standard_D2s_v3"

  resource_group = {
    name     = "rg-test"
    location = "canadacentral"
    id       = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test"
  }

  subnet = {
    id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Network/virtualNetworks/vnet-test/subnets/subnet-test"
  }
}

run "naming_convention" {
  command = plan

  assert {
    condition     = azurerm_windows_virtual_machine.VM.name == "DevSRV-test"
    error_message = "VM name must follow the {env4}{serverType3}-{userDefinedString7}{postfix3} convention"
  }
}

run "default_values" {
  command = plan

  assert {
    condition     = azurerm_windows_virtual_machine.VM.automatic_updates_enabled == true
    error_message = "automatic_updates_enabled must default to true (mapped from enable_automatic_updates)"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.size == "Standard_D2s_v3"
    error_message = "VM size must match var.vm_size"
  }

  assert {
    condition     = length(azurerm_network_security_group.NSG) == 0
    error_message = "NSG must not be created when use_nic_nsg is false (default)"
  }

  assert {
    condition     = length(azurerm_public_ip.VM-EXT-PubIP) == 0
    error_message = "Public IP must not be created when public_ip is false (default)"
  }
}

run "automatic_updates_disabled" {
  command = plan

  variables {
    enable_automatic_updates = false
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.automatic_updates_enabled == false
    error_message = "automatic_updates_enabled must reflect var.enable_automatic_updates when set to false"
  }
}

run "nic_nsg_enabled" {
  command = plan

  variables {
    use_nic_nsg = true
  }

  assert {
    condition     = length(azurerm_network_security_group.NSG) == 1
    error_message = "NSG must be created when use_nic_nsg is true"
  }

  assert {
    condition     = length(azurerm_network_interface_security_group_association.nic-nsg) == 1
    error_message = "NIC-NSG association must be created when use_nic_nsg is true"
  }
}

run "data_disks" {
  command = plan

  variables {
    data_disks = {
      disk1 = {
        disk_size_gb = 128
        lun          = 0
      }
    }
  }

  assert {
    condition     = length(azurerm_managed_disk.data_disks) == 1
    error_message = "One managed disk must be created per data_disks entry"
  }

  assert {
    condition     = length(azurerm_virtual_machine_data_disk_attachment.data_disks) == 1
    error_message = "One data disk attachment must be created per data_disks entry"
  }
}
