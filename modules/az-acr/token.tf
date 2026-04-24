/* Scope Map defines: What the token is allowed to do */
resource "azurerm_container_registry_scope_map" "scope" {
  count = var.enable_token ? 1 : 0

  name                    = "${var.acr_name}-scope"
  resource_group_name     = var.resource_group_name
  container_registry_name = azurerm_container_registry.acr.name

  actions = [
    "repositories/*/content/read",
    "repositories/*/metadata/read"
  ]
}

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

resource "azurerm_container_registry_token_password" "token_pwd" {
  count = var.enable_token ? 1 : 0

  container_registry_token_id = azurerm_container_registry_token.token[0].id

  password1 {}
}

resource "azurerm_key_vault_secret" "acr_token" {
  count = var.enable_token ? 1 : 0

  name         = "${var.acr_name}-token"
  key_vault_id = var.key_vault_id_token

  value = jsonencode({
    username = azurerm_container_registry_token.token[0].name
    password = azurerm_container_registry_token_password.token_pwd[0].password1[0].value
  })
}
