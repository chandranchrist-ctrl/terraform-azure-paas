variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "app_service_plan_id" {
  type = string
}

variable "https_only" {
  type    = bool
  default = true
}

variable "subnet_id" {
  type = string
}

variable "key_vault_secret_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "domain" {
  type = string
}

variable "prod_hostname" {
  type = string
}

variable "uat_hostname" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "godaddy_secret_name" {
  type = string
}

variable "app_logs_sas_url" {
  type = string
}

variable "http_logs_sas_url" {
  type = string
}

variable "app_insights_key" {
  type = string
}

variable "backup_config" {
  description = "Backup configuration for App Service"

  type = object({
    enabled                  = bool
    storage_account_url      = string
    frequency_interval       = number
    frequency_unit           = string
    retention_period_days    = number
    keep_at_least_one_backup = optional(bool, true)
    start_time               = optional(string)
  })
}

variable "public_network_access_enabled" {
  type = bool
}

variable "identity_type" {
  type    = string
  default = "SystemAssigned"
}

variable "remote_debugging_enabled" {
  type    = bool
  default = false
}

variable "ip_restrictions" {
  description = "IP restrictions for App Service"
  type = list(object({
    name       = string
    ip_address = string
    priority   = number
    action     = string
  }))
  default = []
}

variable "enable_app_insights" {
  type    = bool
  default = true
}

variable "storage_account_id" {
  type = string
}