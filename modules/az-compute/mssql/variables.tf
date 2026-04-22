# BASIC SERVER CONFIGURATION
variable "server_name" {
  type = string
}

variable "database_name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "server_version" {
  type    = string
  default = "12.0"
}

variable "sku_name" {
  type = string
}

variable "max_size_gb" {
  type = number
}

variable "collation" {
  type    = string
  default = "SQL_Latin1_General_CP1_CI_AS"
}

# SECURITY - NETWORK ACCESS
variable "enable_public_access" {
  type    = bool
  default = false
}

variable "allowed_ips" {
  type    = list(string)
  default = []
}

variable "enable_outbound_firewall" {
  type    = bool
  default = false
}

# IDENTITY - AZURE AD ADMIN
variable "enable_aad_admin" {
  type    = bool
  default = false
}

variable "azuread_admin_username" {
  type = string
}

variable "azuread_admin_object_id" {
  type    = string
  default = null
}

# KEY VAULT / SECRETS
variable "key_vault_id" {
  type = string
}

variable "sql_secret_name" {
  type = string
}

# TRANSPARENT DATA ENCRYPTION (TDE)
variable "enable_tde" {
  type    = bool
  default = true
}

variable "use_cmk_tde" {
  type    = bool
  default = false
}

variable "key_vault_key_id" {
  type    = string
  default = null
}

# AUDITING
variable "enable_auditing" {
  type    = bool
  default = false
}

variable "audit_storage_endpoint" {
  type    = string
  default = null
}

variable "audit_retention_days" {
  type    = number
  default = 7
}

# SECURITY ALERTS + VA (DEFENDER)
variable "enable_security_alerts" {
  type    = bool
  default = false
}

variable "alerts_state" {
  type    = string
  default = "Enabled"
}

variable "email_account_admins" {
  type    = bool
  default = true
}

variable "email_addresses" {
  type = list(string)
}

variable "alert_retention_days" {
  type    = number
  default = 7
}

variable "enable_va" {
  type    = bool
  default = false
}

variable "va_state" {
  type    = bool
  default = true
}

variable "va_email_account_admins" {
  type    = bool
  default = false
}

variable "va_email_addresses" {
  type    = list(string)
  default = []
}

variable "va_storage_container" {
  type    = string
  default = null
}

variable "va_storage_key" {
  type    = string
  default = null
}

# BACKUP / LONG TERM RETENTION
variable "enable_long_term_retention" {
  type    = bool
  default = false
}

variable "ltr_weekly_retention" {
  type    = string
  default = "P1W"
}

variable "ltr_monthly_retention" {
  type    = string
  default = "P1M"
}

variable "ltr_yearly_retention" {
  type    = string
  default = "P1Y"
}

variable "ltr_week_of_year" {
  type    = number
  default = 1
}

variable "short_term_retention_days" {
  type    = number
  default = 7
}

# NETWORKING (PRIVATE ACCESS)
variable "enable_private_endpoint" {
  type    = bool
  default = false
}

variable "private_subnet_id" {
  type    = string
  default = null
}

# PERFORMANCE / AVAILABILITY
variable "zone_redundant" {
  type    = bool
  default = false
}

variable "read_scale" {
  type    = bool
  default = false
}

variable "storage_account_type" {
  type    = string
  default = "Geo"
}

variable "storage_account_id" {
  type = string
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "app_subnet_id" {
  type = string
}

variable "enable_service_endpoint_mssql" {
  type    = bool
  default = false
}