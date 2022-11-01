terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm  = ">= 1.32.0"
    template = ">= 2.2.0"
  }
}
resource "azurerm_network_security_group" "NSG" {
  count               = var.use_nic_nsg ? 1 : 0
  name                = "${local.vm-name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group.name
  dynamic "security_rule" {
    for_each = [for s in var.security_rules : {
      name                       = s.name
      priority                   = s.priority
      direction                  = s.direction
      access                     = s.access
      protocol                   = s.protocol
      source_port_ranges         = split(",", replace(s.source_port_ranges, "*", "0-65535"))
      destination_port_ranges    = split(",", replace(s.destination_port_ranges, "*", "0-65535"))
      source_address_prefix      = s.source_address_prefix
      destination_address_prefix = s.destination_address_prefix
      description                = s.description
    }]
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_ranges         = security_rule.value.source_port_ranges
      destination_port_ranges    = security_rule.value.destination_port_ranges
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
      description                = security_rule.value.description
    }
  }
  tags = local.tags
}

resource "azurerm_storage_account" "boot_diagnostic" {
  count                    = var.boot_diagnostic ? 1 : 0
  name                     = local.storageName
  resource_group_name      = var.resource_group.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# If public_ip is true then create resource. If not then do not create any
resource "azurerm_public_ip" "VM-EXT-PubIP" {
  count               = var.public_ip ? length(var.nic_ip_configuration.private_ip_address_allocation) : 0
  name                = "${local.vm-name}-pip${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group.name
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = local.tags
}

resource "azurerm_network_interface" "NIC" {
  name                          = "${local.vm-name}-nic1"
  depends_on                    = [var.nic_depends_on]
  location                      = var.location
  resource_group_name           = var.resource_group.name
  enable_ip_forwarding          = var.nic_enable_ip_forwarding
  enable_accelerated_networking = var.nic_enable_accelerated_networking
  dns_servers                   = var.dnsServers
  dynamic "ip_configuration" {
    for_each = var.nic_ip_configuration.private_ip_address_allocation
    content {
      name                          = "ipconfig${ip_configuration.key + 1}"
      subnet_id                     = var.subnet.id
      private_ip_address            = var.nic_ip_configuration.private_ip_address[ip_configuration.key]
      private_ip_address_allocation = var.nic_ip_configuration.private_ip_address_allocation[ip_configuration.key]
      public_ip_address_id          = var.public_ip ? azurerm_public_ip.VM-EXT-PubIP[ip_configuration.key].id : ""
      primary                       = ip_configuration.key == 0 ? true : false
    }
  }
  tags = local.tags
}

resource "azurerm_network_interface_backend_address_pool_association" "LB" {
  for_each = toset(var.load_balancer_backend_address_pools_ids)

  network_interface_id    = azurerm_network_interface.NIC.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = each.key
}

resource "azurerm_network_interface_application_security_group_association" "asg" {
  count                         = var.asg != null ? 1 : 0
  network_interface_id          = azurerm_network_interface.NIC.id
  application_security_group_id = var.asg.id
}

resource "azurerm_network_interface_security_group_association" "nic-nsg" {
  count                     = var.use_nic_nsg ? 1 : 0
  network_interface_id      = azurerm_network_interface.NIC.id
  network_security_group_id = azurerm_network_security_group.NSG[0].id
}

resource "azurerm_windows_virtual_machine" "VM" {
  name                  = local.vm-name
  depends_on            = [var.vm_depends_on]
  location              = var.location
  resource_group_name   = var.resource_group.name
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  computer_name         = local.vm-name
  custom_data           = var.custom_data
  size                  = var.vm_size
  priority              = var.priority
  eviction_policy       = local.eviction_policy
  network_interface_ids = [azurerm_network_interface.NIC.id]
  availability_set_id   = var.availability_set_id
  license_type          = var.license_type == null ? null : var.license_type
  source_image_id       = var.source_image_id
  dynamic "source_image_reference" {
    for_each = var.source_image_id == null ? ["1"] : [] # If there is a source image id provided then don't use source_image_reference
    content {
      publisher = var.storage_image_reference.publisher
      offer     = var.storage_image_reference.offer
      sku       = var.storage_image_reference.sku
      version   = var.storage_image_reference.version
    }
  }
  dynamic "plan" {
    for_each = local.plan
    content {
      name      = local.plan[0].name
      product   = local.plan[0].product
      publisher = local.plan[0].publisher
    }
  }
  provision_vm_agent = true
  os_disk {
    name                 = "${local.vm-name}-osdisk1"
    caching              = var.storage_os_disk.caching
    storage_account_type = var.os_managed_disk_type
    disk_size_gb         = var.storage_os_disk.disk_size_gb
  }
  zone = var.zone
  dynamic "boot_diagnostics" {
    for_each = local.boot_diagnostic
    content {
      storage_account_uri = azurerm_storage_account.boot_diagnostic[0].primary_blob_endpoint
    }
  }
  dynamic "identity" {
    for_each = local.assign-identity
    content {
      type = "SystemAssigned"
    }
  }
  tags = local.tags
  lifecycle {
    ignore_changes = [
      # Ignore changes to username and password because it will require destroying and
      # recreating the VM and all associated resources. It is better handled within the VM post deployment.
      # This will prevent disastrous destruction in case someone plan a name and password change.
      admin_username,
      admin_password,
      identity,
      os_disk, # Prevent restored OS disks from causinf terraform to attempt to re-create the original os disk name and break the restores OS
      custom_data,
    ]
  }
}

resource "azurerm_managed_disk" "data_disks" {
  for_each = var.data_disks

  name                 = "${local.vm-name}-datadisk${each.value.lun + 1}"
  location             = var.resource_group.location
  resource_group_name  = var.resource_group.name
  storage_account_type = try(each.value.storage_account_type, var.data_managed_disk_type)
  create_option        = try(each.value.create_option, "Empty")
  disk_size_gb         = each.value.disk_size_gb
  disk_iops_read_write = try(each.value.disk_iops_read_write, null)
  disk_mbps_read_write = try(each.value.disk_mbps_read_write, null)
  zones                = try(each.value.zone, null)
  lifecycle {
    ignore_changes = [
      name,               # Prevent restored data disks from causing terraform to attempt to re-create the original os disk name and break the restores OS
      create_option,      # Prevent restored data disks from causing terraform to attempt to re-create the original os disk name and break the restores OS
      source_resource_id, # Prevent restored data disks from causing terraform to attempt to re-create the original os disk name and break the restores OS
      tags,               # Prevent restored data disks from causing terraform to attempt to re-create the original os disk name and break the restores OS
    ]
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disks" {
  for_each = var.data_disks

  managed_disk_id    = azurerm_managed_disk.data_disks[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.VM.id
  lun                = each.value.lun
  caching            = try(each.value.caching, "ReadWrite")
  lifecycle {
    ignore_changes = [
      managed_disk_id, # Prevent restored data disks from causing terraform to attempt to re-create the original os disk name and break the restores OS
    ]
  }
}

resource "azurerm_backup_protected_vm" "backup_vm" {
  count               = var.backup ? 1 : 0
  resource_group_name = var.recovery_vault.resource_group_name
  recovery_vault_name = var.recovery_vault.name
  source_vm_id        = azurerm_windows_virtual_machine.VM.id
  backup_policy_id    = var.backup_policy_id
  lifecycle {
    # Required otherwise it want to replace the resource
    ignore_changes = [
      source_vm_id,
    ]
  }
}
