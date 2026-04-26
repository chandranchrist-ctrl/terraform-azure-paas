output "app_insights_id" {
  value = azurerm_application_insights.app.id
}

output "instrumentation_key" {
  value = azurerm_application_insights.app.instrumentation_key
}

output "connection_string" {
  value = azurerm_application_insights.app.connection_string
}