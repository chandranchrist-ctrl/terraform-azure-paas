/* Azure ACR (Managed Identity) - ACR can access Key Vault key for encryption/decryption key */
resource "azurerm_key_vault_access_policy" "acr" {
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
}

# Providing Key Vault write access to Terraform identity
resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = var.key_vault_id_token

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete"
  ]
}

# To give current Terraform user to access ACR
data "azurerm_client_config" "current" {}

resource "azuread_group_member" "current_user_owner" {
  group_object_id  = azuread_group.acr_owner_group.object_id
  member_object_id = data.azurerm_client_config.current.object_id
}

# Groups Creation for the ACR access.
resource "azuread_group" "acr_owner_group" {
  display_name     = "acr-owner-group"
  security_enabled = true
}

resource "azuread_group" "acr_devops_group" {
  display_name     = "acr-devops-group"
  security_enabled = true
}

resource "azurerm_role_assignment" "acr_owner_group_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "Owner"
  principal_id         = azuread_group.acr_owner_group.object_id
}

resource "azurerm_role_assignment" "acr_devops_group_role" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_group.acr_devops_group.object_id
}