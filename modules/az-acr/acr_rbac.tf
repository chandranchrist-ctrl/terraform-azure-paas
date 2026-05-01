# Role Assignment
resource "azurerm_role_assignment" "acr_owner_group_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Owner"
  principal_id         = var.owner_group_id
}

resource "azurerm_role_assignment" "acr_devops_group_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.devops_group_id
}

/* Azure ACR (Managed Identity) - ACR can access Key Vault key for encryption/decryption key */
resource "azurerm_role_assignment" "acr_kv_crypto" {
  scope                = var.key_vault_id_token
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_container_registry.acr.identity[0].principal_id
}