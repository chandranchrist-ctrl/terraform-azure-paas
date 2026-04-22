# Core
variable "env" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

# Firewall Policy related Variables
variable "all_vm_cidrs" {
  type        = list(string)
  description = "List of CIDRs for VM subnets / sources"
}

# NAT Control
variable "enable_public_ip" {
  type        = bool
  description = "Enable Public IP for Azure Firewall (controls NAT rules)"
  default     = true
}

# Firewall Policy
variable "sku" {
  type = string
}

variable "firewall_public_ip" {
  type = string
}

variable "vm_private_ips" {
  description = "List of VM private IPs for NAT rule translations"
  type        = list(string)
  default     = []
}