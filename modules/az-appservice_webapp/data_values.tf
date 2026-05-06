/* Retrieves GoDaddy API credentials from Key Vault for secure DNS operations */
data "azurerm_key_vault_secret" "godaddy" {
  name         = var.godaddy_secret_name
  key_vault_id = var.key_vault_id
}

/* Decodes the secret JSON and safely extracts API key and secret using lookup (avoids failure if keys are missing) */
locals {
  godaddy_credentials = jsondecode(data.azurerm_key_vault_secret.godaddy.value)

  godaddy_api_key    = lookup(local.godaddy_credentials, "Key", null)
  godaddy_api_secret = lookup(local.godaddy_credentials, "Secret", null)
}