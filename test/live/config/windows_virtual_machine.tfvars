# config/windows_virtual_machine.tfvars
# Tracked, ready-to-run fixture for the test/live harness - one representative
# real-usage instance exercising the module's common path, not a two-code-path
# engineered fixture and not a dormant "_" template.
#
# SCOPE: deliberately MINIMAL - the smallest deployable VM (NIC + VM only, no
# NSG/ASG/availability set/data disks/extensions/backup/etc.). Broad
# config-path coverage (NSG, ASG, availability set, public IP, data disks,
# boot diagnostics, every VM extension, backup/Recovery Services Vault,
# encryptDisks, domainToJoin, static IP, etc.) lives instead in the module
# repo's tests/windows_virtual_machine.tftest.hcl (mock_provider - instant,
# free, no real deploy).
#
# vm_size uses the Dav6 family (Standard_D2as_v6) - the sandbox subscription's
# default Dsv5/Dasv5 family quota in canadacentral hits a hard Azure capacity
# restriction; Dav6 quota has already been provisioned for live-test harnesses.
#
# storage_image_reference overrides the module's default 2016-Datacenter SKU
# with the 2022-datacenter-g2 SKU (Windows Server 2022, Generation 2) -
# required for two independent reasons given the mandated Dav6 VM size
# family (Standard_D2as_v6):
#   1. Dav6-family sizes are Generation-2-only ("cannot boot Hypervisor
#      Generation '1'" against the module's default 2016-Datacenter image,
#      which is Gen1-only).
#   2. Dav6-family sizes only support the NVMe disk controller type, and
#      Windows Server 2016 has no NVMe driver support at all regardless of
#      image generation ("Disk Controller Type property 'NVMe' is not
#      supported by the OS image" - confirmed against the Gen2-only
#      2016-datacenter-gensecond SKU too). Per Microsoft's supported-OS-
#      images-for-NVMe list, only Windows Server 2019/2022/2025 (and
#      Windows 10/11) support NVMe - 2016 is excluded outright. 2022 was
#      chosen as the oldest/most minimal image on the NVMe-supported list.
#
# disk_controller_type = "NVMe" is required for the same reason: Dav6-family
# sizes only support the NVMe disk controller type, not the module/
# provider's SCSI default ("InvalidParameter: The VM size ... cannot boot
# with OS image or disk" otherwise). Added to the module itself as a new
# optional input (defaults to null/current SCSI behavior for every other
# caller).
#
# public_ip is not set (defaults to false in main.tf) - no public IPs allowed
# in this environment.

env = "live"

storage_image_reference = {
  publisher = "MicrosoftWindowsServer"
  offer     = "WindowsServer"
  sku       = "2022-datacenter-g2"
  version   = "latest"
}

disk_controller_type = "NVMe"
