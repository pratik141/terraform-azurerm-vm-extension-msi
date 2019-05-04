# create network interface
resource "azurerm_network_interface" "nic" {
  count               = "${var.computer_name["count"]}"
  name                = "${lookup(var.computer_name, count.index)}-${var.environment}-nic"
  location            = "${var.resource_group_location}"
  resource_group_name = "${var.resource_group_name}"

  ip_configuration {
    name                          = "${lookup(var.computer_name, count.index)}-${var.environment}-ipc"
    subnet_id                     = "${var.private_subnet_id[0]}"
    private_ip_address_allocation = "dynamic"
  }

  tags = "${var.tags}"
}

# create virtual machine
resource "azurerm_virtual_machine" "linuxvm" {
  count = "${var.computer_name["count"]}"

  name                  = "${lookup(var.computer_name, count.index)}-${var.environment}"
  location              = "${var.resource_group_location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(concat(azurerm_network_interface.nic.*.id, list("")), count.index)}"]
  vm_size               = "${var.vm_size[0]}"

  delete_os_disk_on_termination = true

  identity = {
    type = "SystemAssigned"
  }

  storage_image_reference {
    id = "${var.custom_image_id}"
  }

  storage_os_disk {
    name              = "os-disk-${lookup(var.computer_name, count.index)}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "${var.disk_size_gb}"
  }

  os_profile {
    computer_name  = "${lookup(var.computer_name, count.index)}"
    admin_username = "${var.vm_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      key_data = "${var.ssh_pub_key}"
      path     = "${var.ssh_auth_path}"
    }
  }

  tags       = "${var.tags}"
  depends_on = ["azurerm_network_interface.nic"]
}

# create machine extension
resource "azurerm_virtual_machine_extension" "virtual_machine_extension" {
  count = "${var.enable_msi == "yes" ? var.computer_name["count"] : 0}"

  name                 = "linux-msi-extn-${lookup(var.computer_name, count.index)}"
  location             = "${var.resource_group_location}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_machine_name = "${lookup(var.computer_name, count.index)}-${var.environment}"
  publisher            = "Microsoft.ManagedIdentity"
  type                 = "ManagedIdentityExtensionForLinux"
  type_handler_version = "1.0"

  settings = <<SETTINGS
    {
        "port": 50342
    }
SETTINGS

  depends_on = ["azurerm_virtual_machine.linuxvm"]
  tags       = "${var.tags}"
}

# Grant the VM identity contributor rights to the current subscription

locals {
  principal_ids = ["${azurerm_virtual_machine.linuxvm.*.identity.0.principal_id}"]
}

resource "azurerm_role_assignment" "role_assignment" {
  count = "${var.enable_msi == "yes" ? var.computer_name["count"] : 0}"

  name                 = "${local.principal_ids[count.index]}"  # "${lookup(var.subscriptions_map, lookup(var.computer_name, count.index) )}"
  scope                = "/subscriptions/${lookup(var.subscriptions_map, lookup(var.computer_name, count.index) )}"
  role_definition_name = "Contributor"
  principal_id         = "${local.principal_ids[count.index]}"

  lifecycle {
    ignore_changes = ["name"]
  }

  depends_on = ["azurerm_virtual_machine_extension.virtual_machine_extension"]
}

## installing packages on VM 
resource "azurerm_virtual_machine_extension" "install_script" {
  count = "${var.install_script == "yes" ? var.computer_name["count"] : 0}"

  name                 = "linux-sh-extn-${lookup(var.computer_name, count.index)}"
  location             = "${var.resource_group_location}"
  resource_group_name  = "${var.resource_group_name}"
  virtual_machine_name = "${lookup(var.computer_name, count.index)}-${var.environment}"
  publisher            = "Microsoft.OSTCExtensions"
  type                 = "CustomScriptForLinux"
  type_handler_version = "1.5"

  settings = <<SETTINGS
  {
  "fileUris": ["${var.shell_settings["fileUris"]}"],
    "commandToExecute": "${var.shell_settings["commandToExecute"]}",
    "timestamp": "${var.deploy_timestamp}"
  }
SETTINGS

  protected_settings = <<SETTINGS
  {
  "storageAccountName": "${var.protected_settings["storageAccountName"]}",
  "storageAccountKey": "${var.protected_settings["storageAccountKey"]}"
  }
SETTINGS

  tags       = "${var.tags}"
  depends_on = ["azurerm_virtual_machine.linuxvm"]
}
