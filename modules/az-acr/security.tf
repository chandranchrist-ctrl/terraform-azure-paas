/* Azure ACR (Managed Identity) - ACR can access Key Vault key for encryption/decryption key */
resource "azurerm_role_assignment" "acr_kv_crypto" {
  scope                = var.key_vault_id_token
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_container_registry.acr.identity[0].principal_id
}

/* resource "azurerm_key_vault_access_policy" "acr" {
  count = var.enable_cmk ? 1 : 0

  key_vault_id = var.key_vault_id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_container_registry.acr.identity[0].principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
  depends_on = [
    azurerm_container_registry.acr
  ]
} */

# Providing Key Vault write access to Terraform identity
# resource "azurerm_key_vault_access_policy" "terraform" {
#   key_vault_id = var.key_vault_id_token

#   tenant_id = data.azurerm_client_config.current.tenant_id
#   object_id = data.azurerm_client_config.current.object_id

#   secret_permissions = [
#     "Get",
#     "List",
#     "Set",
#     "Delete"
#   ]
# }