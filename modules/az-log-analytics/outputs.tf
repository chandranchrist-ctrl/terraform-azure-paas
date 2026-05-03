output "workspace_id" {
  value = one(azurerm_log_analytics_workspace.law[*].id)
}

output "workspace_guid" {
  value = one(azurerm_log_analytics_workspace.law[*].workspace_id)
}
