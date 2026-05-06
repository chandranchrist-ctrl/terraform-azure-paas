/* Creates Application Insights (when enabled) to collect application telemetry like requests, dependencies, and failures, 
integrated with Log Analytics for monitoring and diagnostics */
resource "azurerm_application_insights" "app" {

  count = var.enable_app_insights ? 1 : 0

  name                = var.app_insights_name
  location            = var.location
  resource_group_name = var.resource_group_name

  application_type = "web"

  workspace_id        = var.log_analytics_workspace_id
  sampling_percentage = var.sampling_percentage
  retention_in_days   = var.retention_in_days
}