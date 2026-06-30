variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "west europe"
}

variable "admin_ip" {
  description = "Your public IP address, used to restrict RDP access on the VM NSG"
  type        = string
  sensitive   = true
}

variable "admin_username" {
  description = "Admin username for the Windows VM"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "Admin password for the Windows VM"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "VM size for the lab virtual machine"
  type        = string
  default     = "Standard_B2ts_v2"
}
