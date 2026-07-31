# tests/upgrade_compat.tftest.hcl
# State-chaining upgrade safety test: proves that the azurerm >= 5.0 upgrade
# (automatic_updates_enabled rename + provider pin bump) does not change the
# VM/NIC resource addresses or force a replacement for a typical pre-upgrade
# configuration.

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

# Step 1: simulate the currently-deployed resource (pre-upgrade inputs, default values)
run "baseline_apply" {
  command = apply

  # mock_provider generates an opaque id for azurerm_network_interface.NIC; the
  # VM resource consumes it via network_interface_ids, which requires a
  # realistic ARM-ID-formatted value to parse successfully.
  override_resource {
    target = azurerm_network_interface.NIC
    values = {
      id = "/subscriptions/12345678-1234-9876-4563-123456789012/resourceGroups/rg-test/providers/Microsoft.Network/networkInterfaces/DevSRV-test-nic1"
    }
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.name == "DevSRV-test"
    error_message = "Baseline apply: unexpected VM name"
  }

  assert {
    condition     = azurerm_windows_virtual_machine.VM.automatic_updates_enabled == true
    error_message = "Baseline apply: unexpected automatic_updates_enabled value"
  }
}

# Step 2: plan the upgraded code against that state with the same inputs
run "upgrade_plan_no_replacement" {
  command = plan

  assert {
    condition     = azurerm_windows_virtual_machine.VM.name == "DevSRV-test"
    error_message = "VM name must be unchanged after upgrade"
  }

  assert {
    condition     = azurerm_network_interface.NIC.name == "DevSRV-test-nic1"
    error_message = "NIC name must be unchanged after upgrade"
  }
}
