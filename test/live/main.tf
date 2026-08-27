terraform {
  required_version = ">= 1.9"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Empty on purpose: the state file path is supplied at `terraform init`
  # time via `-backend-config="path=..."` (partial configuration), so the
  # target-branch checkout and the PR-branch checkout can point at the same
  # external state file without either owning its own local state.
  backend "local" {}
}

provider "azurerm" {
  storage_use_azuread             = true
  resource_provider_registrations = "legacy"
  features {
    resource_group {
      # This harness's resource group is fully self-owned by Terraform - no
      # risk of destroying anything not created by this run.
      prevent_deletion_if_contains_resources = false
    }
  }
}

module "windows_virtual_machine" {
  # PR code and baseline code are two on-disk checkouts of this same repo,
  # not two resolved git refs - no pinned ?ref, no version toggle here.
  source = "../../"

  env               = var.env
  serverType        = "SRV"
  userDefinedString = "livetest"
  resource_group    = local.resource_group # from test_dependencies.tf
  subnet            = local.subnet         # from test_dependencies.tf
  tags              = var.tags

  admin_username = "azureadmin"
  admin_password = local.admin_password # random_password, never committed
  vm_size        = var.vm_size

  # No public IPs allowed in this environment.
  public_ip = false

  # Required workaround: bypass_platform_safety_checks_on_user_schedule_enabled
  # defaults to true while patch_mode defaults to null, which azurerm rejects
  # ("patch_mode must be set to AutomaticByPlatform when
  # bypass_platform_safety_checks_on_user_schedule_enabled is set to true").
  # Without this, apply fails for ANY config, not just an expanded one.
  patch_mode = "AutomaticByPlatform"
}
