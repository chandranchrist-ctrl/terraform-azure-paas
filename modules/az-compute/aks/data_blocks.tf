data "azurerm_client_config" "current" {}

data "azurerm_key_vault_secret" "ssh_public_key" {
  name         = var.ssh_secret_name
  key_vault_id = var.key_vault_id
}
