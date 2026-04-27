# Get Current Logged-in User
data "azuread_client_config" "current" {}

# Azure AD Groups
resource "azuread_group" "kv_admins" {
  display_name     = "kv-admins"
  security_enabled = true
}

resource "azuread_group" "kv_devops" {
  display_name     = "kv-devops"
  security_enabled = true
}

# Add ONLY current user to Admin group
resource "azuread_group_member" "current_user_admin" {
  group_object_id  = azuread_group.kv_admins.object_id
  member_object_id = data.azuread_client_config.current.object_id
}

# -------------------------
# Role Assignments (RBAC)
# -------------------------

# Full Admin Access to Key Vault
resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = azuread_group.kv_admins.object_id
}

# DevOps Access (Secrets only)
resource "azurerm_role_assignment" "kv_devops_secrets" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Contributor"
  principal_id         = azuread_group.kv_devops.object_id
}
