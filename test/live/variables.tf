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
