resource "azurerm_role_assignment" "law_monitoring_contributor" {
  count = var.create_law ? 1 : 0

  scope                = one(azurerm_log_analytics_workspace.law[*].id)
  role_definition_name = "Log Analytics Contributor"
  principal_id         = var.owner_group_id
}

resource "azurerm_role_assignment" "law_monitoring_reader" {
  count = var.create_law ? 1 : 0

  scope                = one(azurerm_log_analytics_workspace.law[*].id)
  role_definition_name = "Monitoring Reader"
  principal_id         = var.devops_group_id
}