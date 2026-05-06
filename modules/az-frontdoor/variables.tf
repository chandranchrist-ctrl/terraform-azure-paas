variable "enable_frontdoor" {
  type = bool
}

variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_name" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "apps" {
  type = map(object({
    enabled           = bool
    host_name         = string
    domain            = string
    cert_secret_id    = string
    backend_primary   = string
    backend_secondary = string

    enable_dr = bool

  }))
}

variable "key_vault_id" {
  type = string
}

variable "godaddy_secret_name" {
  type = string
}
