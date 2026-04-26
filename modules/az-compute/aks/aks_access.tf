# Get Current Logged-in User
data "azuread_client_config" "current" {}

# Azure AD Groups
resource "azuread_group" "aks_admins" {
  display_name     = "aks-admins"
  security_enabled = true
}

resource "azuread_group" "aks_devops" {
  display_name     = "aks-devops"
  security_enabled = true
}

# Add ONLY current user to Admin group
resource "azuread_group_member" "current_user_admin" {
  group_object_id  = azuread_group.aks_admins.id
  member_object_id = data.azuread_client_config.current.object_id
}

# -------------------------
# Role Assignments
# -------------------------

# Full Admin Access
resource "azurerm_role_assignment" "aks_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azuread_group.aks_admins.id
}

# DevOps Access (group exists, no users yet)
resource "azurerm_role_assignment" "aks_devops" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = azuread_group.aks_devops.id
}