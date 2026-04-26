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

# Role Assignment
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