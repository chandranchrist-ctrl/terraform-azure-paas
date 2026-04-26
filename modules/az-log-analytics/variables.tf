# Core
variable "env" {
  type = string
}

variable "workload" {
  type = string
}

variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

# Pricing
variable "sku" {
  type    = string
  default = "PerGB2018"
}

# Retention
variable "retention_in_days" {
  type    = number
  default = 30
}

# Cost guard
variable "daily_quota_gb" {
  type    = number
  default = 1
}

# Access control
variable "allow_resource_only_permissions" {
  type    = bool
  default = true
}

variable "local_authentication_enabled" {
  type    = bool
  default = true
}

# Network/query
variable "internet_query_enabled" {
  type    = bool
  default = true
}

# Data lifecycle
variable "immediate_data_purge_on_30_days_enabled" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_monitoring_group" {
  type    = bool
  default = true
}

variable "monitoring_group_name" {
  type    = string
  default = "app-monitoring-readers"
}

variable "add_current_user" {
  type    = bool
  default = true
}