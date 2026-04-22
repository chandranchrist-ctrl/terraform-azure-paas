# Core
variable "env" {
  type = string
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group to create"
}

variable "location" {
  type        = string
  description = "Azure region where the resource group will be created"
}

variable "tags" {
  type        = map(string)
  description = "Tags to assign to the resource group"
  default     = {}
}

# Variables for Firewall Public IP creation
variable "allocation_method" {
  type        = string
  description = "Allocation method for public IP addresses"
  default     = "Static"
}

variable "sku" {
  type        = string
  description = "SKU for the public IP addresses"
  default     = "Standard"
}

#  Variables for Firewall configuration 
variable "sku_name" {
  type        = string
  description = "Azure Firewall SKU name"
  default     = "AZFW_VNet"
}

variable "sku_tier" {
  type        = string
  description = "Tier of Azure Firewall: Basic, Standard, Premium"
  default     = "Standard"
}

variable "zones" {
  type        = list(string)
  description = "Optional list of zones for Azure Firewall"
  default     = []
}

variable "firewall_subnet_id" {
  type = string
}

variable "firewall_management_subnet_id" {
  type = string
}

variable "firewall_policy_id" {
  type        = string
  default     = null
  description = "Firewall Policy ID (required for Standard/Premium)"
}

variable "firewall_mode" {
  type        = string
  description = "public or private firewall mode"
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.firewall_mode)
    error_message = "firewall_mode must be either public or private"
  }
}