variable "env" {
  type = string
}

variable "workload" {
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

variable "acr_name" {
  type = string

}

# SKU
variable "sku" {
  type    = string
  default = "Basic"

  validation {
    condition = contains([
      "Basic",
      "Standard",
      "Premium"
    ], var.sku)

    error_message = "SKU must be exactly: Basic, Standard, or Premium (case-sensitive)."
  }
}

# Admin
variable "admin_enabled" {
  type    = bool
  default = false
}

# Network
variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "allowed_ips" {
  type    = list(string)
  default = []
}

variable "network_bypass_option" {
  type    = string
  default = "AzureServices"
}

# Geo replication
variable "enable_georeplication" {
  type    = bool
  default = false

  validation {
    condition     = !(var.enable_georeplication && var.sku != "Premium")
    error_message = "Geo Replication requires SKU = Premium."
  }
}

variable "replica_locations" {
  type    = list(string)
  default = []
}

# Zone redundancy
variable "zone_redundancy_enabled" {
  type    = bool
  default = false

  validation {
    condition     = !(var.zone_redundancy_enabled && var.sku != "Premium")
    error_message = "Zone Redundancy requires SKU = Premium."
  }
}

# Retention
variable "enable_retention_policy" {
  type    = bool
  default = false
}

variable "retention_days" {
  type = number
}

# Security
variable "export_policy_enabled" {
  type    = bool
  default = false
}

variable "anonymous_pull_enabled" {
  type    = bool
  default = false
}

# Identity
variable "identity_type" {
  type = string
}

# Encryption (CMK)
variable "enable_cmk" {
  type = bool

  validation {
    condition     = !(var.enable_cmk && var.sku != "Premium")
    error_message = "CMK Encryption requires SKU = Premium."
  }
}

variable "key_vault_id" {
  type    = string
  default = null
}

variable "key_vault_id_token" {
  type    = string
  default = null
}

# Data endpoint (Premium only)
variable "enable_data_endpoint" {
  type    = bool
  default = false

  validation {
    condition     = !(var.enable_data_endpoint && var.sku != "Premium")
    error_message = "Data Endpoint requires SKU = Premium."
  }
}

# Private Endpoint
variable "enable_private_endpoint" {
  type    = bool
  default = false

  validation {
    condition     = !(var.enable_private_endpoint && var.sku != "Premium")
    error_message = "Private Endpoint requires SKU = Premium."
  }
}

variable "private_subnet_id" {
  type    = string
  default = null
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

# Token
variable "enable_token" {
  type    = bool
  default = false
}

# Webhook
variable "enable_webhook" {
  type    = bool
  default = false
}

variable "webhook_uri" {
  type    = string
  default = null
}

variable "acr_cmk_id" {
  type    = string
  default = null

  validation {
    condition     = !(var.enable_cmk && var.acr_cmk_id == null)
    error_message = "CMK enabled but Key Vault Key ID is missing."
  }
}