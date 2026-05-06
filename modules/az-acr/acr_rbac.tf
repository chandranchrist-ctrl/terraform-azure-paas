/* Retrieves details of the current Terraform execution identity (used for assigning permissions) */
data "azurerm_client_config" "current" {}

/* Grants Terraform identity permission to manage secrets in Key Vault (required for storing ACR token credentials) */
resource "azurerm_role_assignment" "kv_terraform_access" {
  scope                = var.key_vault_id_token
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

/* Assigns Owner role (management plane only) to the AAD owner group for full administrative control over the ACR resource */
resource "azurerm_role_assignment" "acr_owner_group_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Owner"
  principal_id         = var.owner_group_id
}

/* Assigns custom admin role to AAD admin group for controlled administrative operations on ACR */
resource "azurerm_role_assignment" "acr_admin" {
  scope              = azurerm_container_registry.acr.id
  role_definition_id = azurerm_role_definition.acr_admin_custom.role_definition_resource_id
  principal_id       = var.admin_group_id
}

/* Grants DevOps group push (write) access to upload container images to ACR */
resource "azurerm_role_assignment" "acr_devops_push" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = var.devops_group_id
}

/* Grants DevOps group pull (read) access to download container images from ACR */
resource "azurerm_role_assignment" "acr_devops_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = var.devops_group_id
}

/* Allows ACR managed identity to access Key Vault for encryption/decryption or token secret operations */
resource "azurerm_role_assignment" "acr_kv_crypto" {
  scope                = var.key_vault_id_token
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azurerm_container_registry.acr.identity[0].principal_id
}