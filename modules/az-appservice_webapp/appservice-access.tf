# Get Current User
data "azuread_client_config" "current" {}

# Azure AD Groups
resource "azuread_group" "app_admins" {
  display_name     = "appservice-admins"
  security_enabled = true
}

resource "azuread_group" "app_devops" {
  display_name     = "appservice-devops"
  security_enabled = true
}

# Add ONLY current user to Admin group
resource "azuread_group_member" "current_user_admin" {
  group_object_id  = azuread_group.app_admins.object_id
  member_object_id = data.azuread_client_config.current.object_id
}

# -------------------------
# Role Assignments
# -------------------------

# Admin → Full control
resource "azurerm_role_assignment" "app_admin" {
  scope                = azurerm_linux_web_app.app.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.app_admins.object_id
}

# DevOps → Limited to App Service operations
resource "azurerm_role_assignment" "app_devops" {
  scope                = azurerm_linux_web_app.app.id
  role_definition_name = "Website Contributor"
  principal_id         = azuread_group.app_devops.object_id
}