resource "azurerm_monitor_scheduled_query_rules_alert_v2" "frontend_hits" {
  name                = "appinsights-frontend-hits"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [azurerm_application_insights.app.id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  severity = 2

  criteria {
    query = <<-KQL
      requests
      | summarize requestCount = count()
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThanOrEqual"
    threshold               = 100
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Alert when frontend hits exceed 100 in 5 minutes"
}