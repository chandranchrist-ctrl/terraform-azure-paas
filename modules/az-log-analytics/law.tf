resource "azurerm_log_analytics_workspace" "law" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku               = var.sku
  retention_in_days = var.retention_in_days

  # Cost control
  daily_quota_gb = var.daily_quota_gb

  # Identity (future-ready)
  identity {
    type = "SystemAssigned"
  }

  # Access behavior
  allow_resource_only_permissions = var.allow_resource_only_permissions
  local_authentication_enabled    = var.local_authentication_enabled

  # Network/query behavior
  internet_query_enabled = var.internet_query_enabled

  # Data lifecycle
  immediate_data_purge_on_30_days_enabled = var.immediate_data_purge_on_30_days_enabled

  tags = var.tags
}