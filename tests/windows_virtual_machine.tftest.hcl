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

run "disk_controller_type_default_omitted" {
  command = plan

  assert {
    condition     = azurerm_windows_virtual_machine.VM.name == "DevSRV-test"
    error_message = "Plan must still succeed with disk_controller_type left at its default (null) - VM name should be unaffected"
  }
}

run "disk_controller_type_nvme" {
  command = plan

  variables {
    disk_controller_type = "NVMe"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.disk_controller_type == "NVMe"
    error_message = "disk_controller_type must be passed through when var.disk_controller_type is set"
  }
}

run "new_optional_vm_arguments_default_omitted" {
  command = plan

  # allow_extension_operations, disk_controller_type, and hotpatching_enabled
  # are optional+computed in the provider schema - their plan-time value is
  # unknown (not null) when unset, so they're covered by the "plan succeeds
  # unchanged" assertions here instead of a direct null check.
  assert {
    condition     = azurerm_windows_virtual_machine.VM.name == "DevSRV-test"
    error_message = "Plan must still succeed with all new optional arguments left at their defaults"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.capacity_reservation_group_id == null
    error_message = "capacity_reservation_group_id must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.dedicated_host_group_id == null
    error_message = "dedicated_host_group_id must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.dedicated_host_id == null
    error_message = "dedicated_host_id must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.edge_zone == null
    error_message = "edge_zone must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.encryption_at_host_enabled == null
    error_message = "encryption_at_host_enabled must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.proximity_placement_group_id == null
    error_message = "proximity_placement_group_id must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.reboot_setting == null
    error_message = "reboot_setting must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.secure_boot_enabled == null
    error_message = "secure_boot_enabled must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.vtpm_enabled == null
    error_message = "vtpm_enabled must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.timezone == null
    error_message = "timezone must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.user_data == null
    error_message = "user_data must be null by default"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.virtual_machine_scale_set_id == null
    error_message = "virtual_machine_scale_set_id must be null by default"
  }
}

run "new_optional_vm_arguments_set" {
  command = plan

  variables {
    allow_extension_operations = true
    encryption_at_host_enabled = true
    hotpatching_enabled        = true
    patch_mode                 = "AutomaticByPlatform"
    reboot_setting             = "IfRequired"
    secure_boot_enabled        = true
    vtpm_enabled               = true
    timezone                   = "UTC"
    user_data                  = "dGVzdA=="
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.allow_extension_operations == true
    error_message = "allow_extension_operations must be passed through when set"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.encryption_at_host_enabled == true
    error_message = "encryption_at_host_enabled must be passed through when set"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.hotpatching_enabled == true
    error_message = "hotpatching_enabled must be passed through when set"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.reboot_setting == "IfRequired"
    error_message = "reboot_setting must be passed through when set"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.secure_boot_enabled == true
    error_message = "secure_boot_enabled must be passed through when set"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.vtpm_enabled == true
    error_message = "vtpm_enabled must be passed through when set"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.timezone == "UTC"
    error_message = "timezone must be passed through when set"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.user_data == "dGVzdA=="
    error_message = "user_data must be passed through when set"
  }
}

run "capacity_reservation_group_id_set" {
  command = plan

  variables {
    capacity_reservation_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/capacityReservationGroups/crg-test"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.capacity_reservation_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/capacityReservationGroups/crg-test"
    error_message = "capacity_reservation_group_id must be passed through when set"
  }
}

run "proximity_placement_group_id_set" {
  command = plan

  variables {
    proximity_placement_group_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/proximityPlacementGroups/ppg-test"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.proximity_placement_group_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/proximityPlacementGroups/ppg-test"
    error_message = "proximity_placement_group_id must be passed through when set"
  }
}

run "dedicated_host_id_set" {
  command = plan

  variables {
    dedicated_host_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/hostGroups/hg-test/hosts/host-test"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.dedicated_host_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/hostGroups/hg-test/hosts/host-test"
    error_message = "dedicated_host_id must be passed through when set"
  }
}

run "virtual_machine_scale_set_id_set" {
  command = plan

  variables {
    virtual_machine_scale_set_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-test"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.virtual_machine_scale_set_id == "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-test"
    error_message = "virtual_machine_scale_set_id must be passed through when set"
  }
}
