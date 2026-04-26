variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "workspace_id" {
  description = "Log Analytics Workspace ID"
  type        = string
}

variable "action_group_id" {
  type = string
}

variable "sampling_percentage" {
  type = number
}

variable "retention_in_days" {
  type = number
}