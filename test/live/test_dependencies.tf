# test_dependencies.tf
# Self-contained dependency resources, owned entirely by this harness.
#
# Deliberately NOT reusing any shared/production resource group, vnet, or
# subnet: writing into a shared L1-managed "Network" RG usually requires
# elevated, L1-scoped permissions. A dedicated throwaway RG + vnet + subnet
# here needs only Contributor on the sandbox subscription and can never
# collide with or affect any production resource.
#
# The admin_password is generated locally via random_password instead of
# being committed anywhere (as tfvars or otherwise) - the harness never
# needs a literal secret on disk.

resource "azurerm_resource_group" "live_test" {
  # PR-number suffix keeps two concurrently open PRs against this module from
  # colliding on the same sandbox resource group.
  name     = "${var.env}-caf-windows-vm-live-test-${var.pr_number}-rg"
  location = var.location

  tags = {
    "pr-number" = var.pr_number
  }
}

resource "azurerm_virtual_network" "live_test" {
  name                = "${var.env}-caf-windows-vm-live-test-${var.pr_number}-vnet"
  address_space       = ["10.251.0.0/16"] # arbitrary, unpeered - collision-safe by construction
  location            = azurerm_resource_group.live_test.location
  resource_group_name = azurerm_resource_group.live_test.name
}

resource "azurerm_subnet" "live_test" {
  name                 = "${var.env}-caf-windows-vm-live-test-${var.pr_number}-snet"
  resource_group_name  = azurerm_resource_group.live_test.name
  virtual_network_name = azurerm_virtual_network.live_test.name
  address_prefixes     = ["10.251.0.0/24"]
}

resource "random_password" "live_test" {
  length      = 24
  special     = true
  min_upper   = 2
  min_lower   = 2
  min_numeric = 2
  min_special = 2
}

locals {
  # terraform-azurerm-caf-windows_virtual_machine expects resource_group.{id,name,location}.
  resource_group = {
    id       = azurerm_resource_group.live_test.id
    name     = azurerm_resource_group.live_test.name
    location = azurerm_resource_group.live_test.location
  }
  subnet         = azurerm_subnet.live_test
  admin_password = random_password.live_test.result
}
