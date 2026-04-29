resource "null_resource" "uat_txt_dns" {
  triggers = {
    txt = azurerm_linux_web_app.app.custom_domain_verification_id
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

$body = '[{"data":"${lower(azurerm_linux_web_app.app.custom_domain_verification_id)}","ttl":600}]'

Invoke-RestMethod -Method Put `
  -Uri "https://api.godaddy.com/v1/domains/${var.domain}/records/TXT/asuid.${var.uat_hostname}" `
  -Headers $headers `
  -Body $body
EOT
  }
}

resource "null_resource" "uat_cname_dns" {
  triggers = {
    target = azurerm_linux_web_app_slot.uat.default_hostname
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

$body = '[{"data":"${azurerm_linux_web_app_slot.uat.default_hostname}","ttl":600}]'

Invoke-RestMethod -Method Put `
  -Uri "https://api.godaddy.com/v1/domains/${var.domain}/records/CNAME/${var.uat_hostname}" `
  -Headers $headers `
  -Body $body
EOT
  }
}

resource "azurerm_app_service_custom_hostname_binding" "uat" {
  hostname            = "${var.uat_hostname}.${var.domain}"
  app_service_name    = azurerm_linux_web_app.app.name
  resource_group_name = var.resource_group_name

  depends_on = [
    null_resource.uat_txt_dns,
    null_resource.uat_cname_dns
  ]
}

resource "azurerm_app_service_certificate_binding" "uat" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.uat.id
  ssl_state           = "SniEnabled"
  certificate_id      = azurerm_app_service_certificate.cert.id
}