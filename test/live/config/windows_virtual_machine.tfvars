# config/windows_virtual_machine.tfvars
# Tracked, ready-to-run fixture for the test/live harness - one representative
# real-usage instance exercising the module's common path, not a two-code-path
# engineered fixture and not a dormant "_" template.
#
# SCOPE: deliberately MINIMAL - the smallest deployable VM (NIC + VM only, no
# NSG/ASG/availability set/data disks/extensions/backup/etc.). Broad
# config-path coverage (NSG, ASG, availability set, public IP, data disks,
# boot diagnostics, every VM extension, backup/Recovery Services Vault,
# encryptDisks, domainToJoin, custom storage_image_reference, static IP,
# etc.) lives instead in the module repo's tests/windows_virtual_machine.tftest.hcl
# (mock_provider - instant, free, no real deploy).
#
# vm_size uses the Dav6 family (Standard_D2as_v6) - the sandbox subscription's
# default Dsv5/Dasv5 family quota in canadacentral hits a hard Azure capacity
# restriction; Dav6 quota has already been provisioned for live-test harnesses.
#
# public_ip is not set (defaults to false in main.tf) - no public IPs allowed
# in this environment.

env = "live"
