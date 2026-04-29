variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "log_analytics_workspace_id" {
  type = string
}

variable "aks_id" {
  type = string
}

variable "action_group_id" {
  description = "Action Group ID for alerts"
  type        = string
}

variable "aks_dcr_name" {
  type = string
}

variable "aks_dcr_association" {
  type = string
}

variable "enabled" {
  type    = bool
  default = false
}