variable "name" {
  type = string
}


variable "env" {
  type = string
}

variable "workload" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "sku_tier" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "dns_prefix_private_cluster" {
  type = string
}

variable "private_cluster_enabled" {
  type = bool
}

variable "private_cluster_public_fqdn_enabled" {
  type = bool
}

variable "private_dns_zone_id" {
  type    = string
  default = null
}

variable "automatic_upgrade_channel" {
  type = string
}

variable "node_os_upgrade_channel" {
  type = string
}

variable "api_server_access_profile" {
  type = any
}

variable "auto_scaler_profile" {
  type = any
}

variable "role_based_access_control_enabled" {
  type = bool
}

variable "disk_encryption_set_id" {
  type    = string
  default = null
}

variable "http_application_routing_enabled" {
  type = bool
}

variable "identity" {
  type = any
}

variable "kubelet_identity" {
  type    = any
  default = null
}

variable "local_account_disabled" {
  type = bool
}

variable "monitor_metrics" {
  type = bool
}

variable "network_profile" {
  type = any
}

variable "oidc_issuer_enabled" {
  type = bool
}

variable "workload_identity_enabled" {
  type = bool
}

variable "storage_profile" {
  type = any
}

variable "support_plan" {
  type = string
}

variable "run_command_enabled" {
  type = bool
}

variable "tags" {
  type = map(string)
}

variable "default_node_pool" {
  type = object({
    name                 = string
    vm_size              = string
    auto_scaling_enabled = bool
    node_count           = optional(number)
    min_count            = optional(number)
    max_count            = optional(number)
    vnet_subnet_id       = string
  })
}

variable "node_pools" {
  type = map(object({
    name                 = string
    vm_size              = string
    auto_scaling_enabled = bool
    node_count           = optional(number)
    min_count            = optional(number)
    max_count            = optional(number)
    vnet_subnet_id       = string
  }))
}

variable "extensions" {
  type    = map(any)
  default = {}
}

variable "deployment_safeguard" {
  type = any
}

variable "trusted_access" {
  type    = map(any)
  default = {}
}

variable "enable_maintenance_window" {
  type    = bool
  default = false
}

variable "enable_defender" {
  type        = bool
  default     = false
  description = "Enable Microsoft Defender for AKS integration"
}

variable "defender_workspace_id" {
  type    = string
  default = null

  validation {
    condition     = var.enable_defender == false || var.defender_workspace_id != null
    error_message = "defender_workspace_id must be provided when enable_defender is true."
  }
}

variable "enable_oms_agent" {
  type    = bool
  default = false
}

variable "log_analytics_workspace_id" {
  type    = string
  default = null
}

variable "enable_backup_trusted_access" {
  type    = bool
  default = false
}


variable "enable_trusted_access" {
  type    = bool
  default = false
}

variable "enable_ssh" {
  type    = bool
  default = false
}

variable "admin_username" {
  type = string
}

variable "ssh_secret_name" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "aad_rbac" {
  type = object({
    enabled            = bool
    azure_rbac_enabled = bool
  })
}

variable "acr_id" {
  type = string
}