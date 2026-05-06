# Core
variable "env" {
  description = "Prefix for route table names"
  type        = string
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

variable "app_insights_connection_string" {
  type      = string
  default   = null
  sensitive = true
}

variable "app_insights_instrumentation_key" {
  type      = string
  default   = null
  sensitive = true
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

variable "storage_account_id" {
  type = string
}

variable "owner_group_id" {
  type = string
}

variable "devops_group_id" {
  type = string
}

###

variable "enable_app_insights" {
  type    = bool
  default = false
}

variable "app_insights_name" {
  type    = string
  default = null
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "sampling_percentage" {
  type    = number
  default = 100
}

variable "retention_in_days" {
  type    = number
  default = 30
}

variable "app_access_mode" {
  type = string
}

variable "private_dns_zone_ids" {
  type    = list(string)
  default = []
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = null
}

variable "scm_allowed_ips" {
  description = "SCM allowed IPs"
  type        = list(string)
  default     = []
}

variable "scm_use_main_ip_restriction" {
  type    = bool
  default = false
}

variable "api_url" {
  type = string
}