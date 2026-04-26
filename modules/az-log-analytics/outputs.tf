output "workspace_id" {
  value = azurerm_log_analytics_workspace.law.id
}

output "workspace_guid" {
  value = azurerm_log_analytics_workspace.law.workspace_id
}

output "monitoring_group_id" {
  value = try(azuread_group.monitoring_readers[0].id, null)
}