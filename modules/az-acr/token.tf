/* Scope Map defines: What the token is allowed to do */
resource "azurerm_container_registry_scope_map" "scope" {
  count = var.enable_token ? 1 : 0

  name                    = "${var.acr_name}-scope"
  resource_group_name     = var.resource_group_name
  container_registry_name = azurerm_container_registry.acr.name

  actions = [
    "repositories/*/content/read",
    "repositories/*/content/write",
    "repositories/*/metadata/read"
  ]
}

/* Creates an ACR token (data-plane identity) with defined scope map to enable controlled access (e.g., push/pull) when token-based auth is enabled */
resource "azurerm_container_registry_token" "token" {
  count = var.enable_token ? 1 : 0

  name                    = "${var.acr_name}-token"
  container_registry_name = azurerm_container_registry.acr.name
  resource_group_name     = var.resource_group_name
  scope_map_id            = azurerm_container_registry_scope_map.scope[0].id

  depends_on = [
    azurerm_container_registry_scope_map.scope
  ]
}

/* Generates password credentials for the ACR token, used for authenticating against the registry */
resource "azurerm_container_registry_token_password" "token_pwd" {
  count = var.enable_token ? 1 : 0

  container_registry_token_id = azurerm_container_registry_token.token[0].id

  password1 {}
}

/* Stores ACR token credentials (username & password) securely in Key Vault as a JSON secret for external consumption */
resource "azurerm_key_vault_secret" "acr_token" {
  count = var.enable_token ? 1 : 0

  name         = "${var.acr_name}-token"
  key_vault_id = var.key_vault_id_token

  depends_on = [
    azurerm_role_assignment.kv_terraform_access,
    azurerm_container_registry_token_password.token_pwd,
  ]

  value = jsonencode({
    username = azurerm_container_registry_token.token[0].name
    password = azurerm_container_registry_token_password.token_pwd[0].password1[0].value
  })
}
