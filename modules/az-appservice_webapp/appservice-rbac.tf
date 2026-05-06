/* Retrieves Azure App Service principal to grant it access to Key Vault for resolving secrets (e.g., certificates) */
data "azuread_service_principal" "appservice" {
  display_name = "Microsoft Azure App Service"
}

/* Grants Azure App Service platform permission to read secrets from Key Vault (required for features like Key Vault references) */
resource "azurerm_role_assignment" "kv_appservice_access" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azuread_service_principal.appservice.object_id
}

/* Grants Web App managed identity permission to read secrets from Key Vault for runtime access */
resource "azurerm_role_assignment" "kv_access" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

/* Grants Web App managed identity permission to manage/read certificates from Key Vault (used for custom domain SSL) */
resource "azurerm_role_assignment" "kv_cert_access" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

/* Grants Web App managed identity access to storage account for writing logs or accessing blobs */
resource "azurerm_role_assignment" "storage_access" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_web_app.app.identity[0].principal_id
}

/* Grants owner group Contributor access (management plane) to fully manage the App Service */
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