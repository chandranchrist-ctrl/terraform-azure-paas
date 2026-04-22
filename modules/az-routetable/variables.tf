# Core
variable "env" {
  description = "Prefix for route table names"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
  default     = {}
}


# Voriables related to route table creation
variable "create_rt" {
  description = "Flag to create route tables"
  type        = bool
  default     = true
}

# Network - Routing
variable "firewall_ip" {
  description = "Optional firewall private IP for VirtualAppliance routes"
  type        = string
  default     = null
}

variable "subnets_map" {
  type = map(string)
}