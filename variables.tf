variable "resource_group_name" {
  description = "resource group name"
}

variable "resource_group_location" {
  description = "The region where to deploy the resource/infrastructure (e.g. East US)."
  default     = "West Europe"
}

variable "private_subnet_id" {
  type        = "list"
  description = "describe your private subnet id"
}

variable "vm_username" {
  description = "describe your variable"
}

variable "computer_name" {
  type        = "map"
  description = "describe your computer name"
}

variable "vm_size" {
  type        = "list"
  description = "VM size"
}

variable "custom_image_id" {
  type = "string"
}

variable "tags" {
  type        = "map"
  description = "Tags"
}

variable "ssh_pub_key" {
  type        = "string"
  description = "Public SSH Key "
}

variable "ssh_auth_path" {
  type        = "string"
  description = "ssh authorized_keys file on the virtual machine /home/${username}/.ssh/authorized_keys"
}

variable "disk_size_gb" {
  type        = "string"
  description = "Specifies the size of the data disk in gigabytes"
}

variable "environment" {}

variable "subscriptions_map" {
  type        = "map"
  default     = { 
                vm1 = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
                vm2 = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
                }
  description = "describe your variable"
}

variable "enable_msi" {
  type        = "string"
  description = "describe your variable"
  default     = "no"
}

variable "install_script" {
  type        = "string"
  description = "describe your variable"
  default     = "no"
}

variable "protected_settings" {
  type        = "map"
  description = "describe your variable"
  default     = {}
}

variable "deploy_timestamp" {
  type        = "string"
  description = "describe your variable"
  default     = "default_value"
}

variable "shell_settings" {
  type        = "map"
  description = "describe your variable"
  default     = {}
}
