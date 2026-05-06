/* Retrieves GoDaddy API credentials (stored as a secret) from Key Vault for secure DNS automation */
data "azurerm_key_vault_secret" "godaddy" {
  name         = var.godaddy_secret_name
  key_vault_id = var.key_vault_id
}

/* Decodes GoDaddy credentials and extracts API key/secret for use in DNS record creation */
locals {
  godaddy_credentials = jsondecode(data.azurerm_key_vault_secret.godaddy.value)

  godaddy_api_key    = local.godaddy_credentials.Key
  godaddy_api_secret = local.godaddy_credentials.Secret
}

/* Creates DNS TXT records in GoDaddy for Front Door domain validation using API calls */
resource "null_resource" "frontdoor_txt_dns_record" {

  for_each = local.enabled ? var.apps : {}

  triggers = {
    host = each.value.host_name
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

$subdomain = "${each.value.host_name}".Split('.')[0]

$body = '[{"data":"frontdoor-validation-token","ttl":600}]'

Invoke-RestMethod -Method Put `
  -Uri "https://api.godaddy.com/v1/domains/${each.value.domain}/records/TXT/_dnsauth.$subdomain" `
  -Headers $headers `
  -Body $body
EOT
  }
}

/* Creates CNAME records in GoDaddy pointing custom domains to Front Door endpoint for traffic routing */
resource "null_resource" "frontdoor_cname_dns_record" {

  for_each = local.enabled ? var.apps : {}

  triggers = {
    endpoint = azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint[0].host_name
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
$headers = @{
  Authorization = "sso-key ${local.godaddy_api_key}:${local.godaddy_api_secret}"
  "Content-Type" = "application/json"
}

$subdomain = "${each.value.host_name}".Split('.')[0]

$body = '[{"data":"${azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint[0].host_name}","ttl":600}]'

Invoke-RestMethod -Method Put `
  -Uri "https://api.godaddy.com/v1/domains/${each.value.domain}/records/CNAME/$subdomain" `
  -Headers $headers `
  -Body $body
EOT
  }
}