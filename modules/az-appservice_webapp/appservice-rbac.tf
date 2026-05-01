data "azuread_service_principal" "appservice" {
  display_name = "Microsoft Azure App Service"
}

resource "azurerm_role_assignment" "kv_appservice_access" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_service_principal.appservice.object_id
}

resource "azurerm_role_assignment" "kv_access" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

resource "azurerm_role_assignment" "kv_cert_access" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

resource "azurerm_role_assignment" "storage_access" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

# Admin → Full control
resource "azurerm_role_assignment" "app_admin" {
  scope                = azurerm_linux_web_app.app.id
  role_definition_name = "Contributor"
  principal_id         = var.owner_group_id
}

# DevOps → Limited access
resource "azurerm_role_assignment" "app_devops" {
  scope                = azurerm_linux_web_app.app.id
  role_definition_name = "Website Contributor"
  principal_id         = var.devops_group_id
}