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

    depends_on = [
    azuread_group.kv_admins,
    azurerm_key_vault.kv
  ]
}

# DevOps Access (Secrets only)
resource "azurerm_role_assignment" "kv_devops" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Contributor"
  principal_id         = azuread_group.kv_devops.object_id

    depends_on = [
    azuread_group.kv_devops,
    azurerm_key_vault.kv
  ]
}

resource "time_sleep" "rbac_propagation" {
  depends_on = [
    azurerm_role_assignment.kv_admin,
    azurerm_role_assignment.kv_devops
  ]

  create_duration = "120s"
}