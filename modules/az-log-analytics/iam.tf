/* Grants the owner group full contributor permissions on the Log Analytics Workspace to manage configurations, data, and settings */
resource "azurerm_role_assignment" "law_monitoring_contributor" {
  count = var.create_law ? 1 : 0

  scope                = one(azurerm_log_analytics_workspace.law[*].id)
  role_definition_name = "Log Analytics Contributor"
  principal_id         = var.owner_group_id
}

/* Grants the DevOps group read-only monitoring access to view logs, metrics, and insights without modifying resources */
resource "azurerm_role_assignment" "law_monitoring_reader" {
  count = var.create_law ? 1 : 0

  scope                = one(azurerm_log_analytics_workspace.law[*].id)
  role_definition_name = "Monitoring Reader"
  principal_id         = var.devops_group_id
}