/* Creates TXT DNS record for domain ownership verification in GoDaddy before binding custom domain to App Service */
resource "null_resource" "prod_txt_dns" {

  count = local.is_private ? 0 : 1

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
  -Uri "https://api.godaddy.com/v1/domains/${var.domain}/records/TXT/asuid.${var.prod_hostname}" `
  -Headers $headers `
  -Body $body
EOT
  }
}

/* Creates CNAME DNS record pointing production hostname to App Service default hostname for routing traffic */
resource "null_resource" "prod_cname_dns" {

  count = local.is_private ? 0 : 1

  triggers = {
    target = azurerm_linux_web_app.app.default_hostname
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

$body = '[{"data":"${azurerm_linux_web_app.app.default_hostname}","ttl":600}]'

Invoke-RestMethod -Method Put `
  -Uri "https://api.godaddy.com/v1/domains/${var.domain}/records/CNAME/${var.prod_hostname}" `
  -Headers $headers `
  -Body $body
EOT
  }
}

/* Binds custom production domain to App Service after DNS validation is complete, enabling user-friendly URL access */
resource "azurerm_app_service_custom_hostname_binding" "prod" {

  count = local.is_private ? 0 : 1

  hostname            = "${var.prod_hostname}.${var.domain}"
  app_service_name    = azurerm_linux_web_app.app.name
  resource_group_name = var.resource_group_name

  depends_on = [
    null_resource.prod_txt_dns,
    null_resource.prod_cname_dns
  ]
}

/* Binds SSL certificate to production custom domain using SNI for secure HTTPS communication */
resource "azurerm_app_service_certificate_binding" "prod" {

  count = local.is_private ? 0 : 1

  hostname_binding_id = azurerm_app_service_custom_hostname_binding.prod[0].id
  ssl_state           = "SniEnabled"
  certificate_id      = azurerm_app_service_certificate.cert[0].id
}