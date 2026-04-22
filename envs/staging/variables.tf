variable "subscription_id" {}

variable "storage_account_name" {
  type    = string
  default = ""
}
variable "key_vault_name" {
  type    = string
  default = ""
}

variable "storage_accounts" {
  type = map(string)
}

variable "sql_logs_storage_account_name" {
  type = string
}