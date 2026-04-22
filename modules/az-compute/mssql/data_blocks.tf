data "azurerm_client_config" "current" {}

data "azurerm_key_vault_secret" "sql_credentials" {
  name         = var.sql_secret_name
  key_vault_id = var.key_vault_id
}

locals {
  sql_creds = jsondecode(data.azurerm_key_vault_secret.sql_credentials.value)
}