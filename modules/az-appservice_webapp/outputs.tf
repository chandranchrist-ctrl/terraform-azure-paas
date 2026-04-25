output "default_hostname" {
  value = azurerm_linux_web_app.app.default_hostname
}

output "prod_url" {
  value = "https://${var.prod_hostname}.${var.domain}"
}

output "uat_url" {
  value = "https://${var.uat_hostname}.${var.domain}"
}