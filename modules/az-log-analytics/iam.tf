data "azuread_client_config" "current" {}

resource "azuread_group" "monitoring_readers" {
  count = var.create_monitoring_group ? 1 : 0

  display_name     = var.monitoring_group_name
  security_enabled = true
}

resource "azuread_group_member" "current_user" {
  count = var.create_monitoring_group && var.add_current_user ? 1 : 0

  group_object_id  = azuread_group.monitoring_readers[0].id
  member_object_id = data.azuread_client_config.current.object_id
}

resource "azurerm_role_assignment" "law_monitoring_reader" {
  count = var.create_monitoring_group ? 1 : 0

  scope                = azurerm_log_analytics_workspace.law.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azuread_group.monitoring_readers[0].id
}