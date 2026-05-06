output "default_hostname" {
  value = azurerm_linux_web_app.app.default_hostname
}

output "prod_url" {
  value = "https://${var.prod_hostname}.${var.domain}"
}

output "uat_url" {
  value = "https://${var.uat_hostname}.${var.domain}"
}

output "app_insights_connection_string" {
  value = try(azurerm_application_insights.app[0].connection_string, null)
}

output "outbound_ips" {
  value = split(",", azurerm_linux_web_app.app.outbound_ip_addresses)
}