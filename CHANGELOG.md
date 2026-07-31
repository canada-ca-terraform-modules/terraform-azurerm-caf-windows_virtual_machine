## v3.0.17 (Jul 2026)

FEATURES:

IMPROVEMENTS:

* Upgrade module to support azurerm provider `~> 5.0` (target: 5.0.1)
* Move `required_providers`/`required_version` into dedicated `providers.tf`, pinned to `azurerm ~> 5.0`
* Drop unused `template` provider requirement (no resource in the module used it)
* Add `.tflint.hcl` (azurerm ruleset), `.gitattributes` (enforce LF), and a standard `.gitignore`
* Add `tests/*.tftest.hcl` (mock_provider) covering naming convention, default values, and upgrade compatibility
* Add `.github/workflows/terraform-ci.yml` (fmt, validate, test, tflint) and bump `documentation.yml` action pins (`actions/checkout@v7.0.1`, `terraform-docs/gh-actions@v1.4.1`)

BUGS:

* Fix `azurerm_windows_virtual_machine.VM`: removed/deprecated `enable_automatic_updates` argument replaced with `automatic_updates_enabled` (azurerm 5.0 breaking change). The module input variable name `enable_automatic_updates` is unchanged, so no caller tfvars changes are required.

Known blockers:

* None. No other resource in this module (`azurerm_network_security_group`, `azurerm_storage_account`, `azurerm_public_ip`, `azurerm_network_interface`, `azurerm_network_interface_*_association`, `azurerm_managed_disk`, `azurerm_virtual_machine_data_disk_attachment`, `azurerm_backup_protected_vm`, `azurerm_virtual_machine_extension`, `azurerm_resource_group_template_deployment`) has breaking changes between the currently declared `>= 1.32.0` constraint and azurerm 5.0.1.

## v1.1.1 (Aug 2020)

FEATURES: 

* Add support for custom_data execution on WIndows 10
  
IMPROVEMENTS:

BUGS:

* Fix issue with autoshutdown resource name

## v1.1.0 (Aug 2020)

FEATURES: 

* Add support for terraform v0.13
* Remove deploy
  
IMPROVEMENTS:

* Fix output error when deploy is false
* Add support for domain_join depends_on
* Add support for ASG association

BUGS:

## v1.0.2 (July 2020)

FEATURES: 

IMPROVEMENTS:

* Fix output error when deploy is false
* Add support for domain_join depends_on
* Add support for ASG association

BUGS:

## v1.0.1 (June 2020)

FEATURES: 

IMPROVEMENTS:

* Add virtual machine name validation/creation

BUGS:

## v1.0.0 (June 2020)

FEATURES: 
* **new feature:**  Initial release

IMPROVEMENTS:

BUGS:
