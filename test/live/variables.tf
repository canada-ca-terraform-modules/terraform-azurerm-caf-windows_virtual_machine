variable "env" {
  description = "4 chars defining the environment name prefix for the VM"
  type        = string
  default     = "live"
}

variable "location" {
  description = "Location for the throwaway live-test resource group (+ vnet/subnet)"
  type        = string
  default     = "canadacentral"
}

variable "tags" {
  description = "Tags applied to the VM resources created by this harness"
  type        = map(string)
  default = {
    purpose = "module-live-test"
  }
}

variable "pr_number" {
  description = <<-EOT
    Suffix applied to test_dependencies.tf resource names so concurrent PRs
    against this module never collide on the same sandbox subscription. CI
    sources this from `TF_VAR_pr_number` (`github.event.number`); manual runs
    can leave the default or pass their own value.
  EOT
  type        = string
  default     = "manual"
}

variable "vm_size" {
  description = "Specifies the size of the Virtual Machine. Always use the Dav6 family in this sandbox (e.g. Standard_D2as_v6) - the default Dsv5/Dasv5 quota hits a hard capacity restriction in canadacentral."
  type        = string
  default     = "Standard_D2as_v6"
}

variable "storage_image_reference" {
  description = "OS image reference for the VM. Overridden in the tracked fixture to a Generation 2 SKU - the Dav6 VM size family required in this sandbox can only boot Generation 2 images."
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

variable "disk_controller_type" {
  description = "Disk controller type for the VM. Overridden to NVMe in the tracked fixture - the Dav6 VM size family required in this sandbox only supports the NVMe disk controller type (rejects the module/provider's SCSI default at create time)."
  type        = string
  default     = null
}
