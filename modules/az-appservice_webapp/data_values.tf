data "azurerm_key_vault_secret" "godaddy" {
  name         = var.godaddy_secret_name
  key_vault_id = var.key_vault_id
}

locals {
  godaddy_credentials = jsondecode(data.azurerm_key_vault_secret.godaddy.value)

  godaddy_api_key    = lookup(local.godaddy_credentials, "Key", null)
  godaddy_api_secret = lookup(local.godaddy_credentials, "Secret", null)
}