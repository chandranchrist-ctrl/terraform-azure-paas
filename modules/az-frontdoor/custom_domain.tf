/* Creates Front Door custom domains for each enabled app, binding user-friendly domains with TLS certificates (from Key Vault) to the Front Door profile */
resource "azurerm_cdn_frontdoor_custom_domain" "frontdoor_custom_domain" {

  for_each = local.enabled ? {
    for k, v in var.apps : k => v if v.enabled
  } : {}

  depends_on = [
    time_sleep.wait_for_fe_dns
  ]

  name                     = "${var.name}-${each.key}-custom-domain"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile[0].id

  host_name = each.value.host_name

  tls {
    certificate_type        = "CustomerCertificate"
    cdn_frontdoor_secret_id = azurerm_cdn_frontdoor_secret.frontdoor_secret[each.key].id
  }
}

/* Associates each custom domain with its respective Front Door route to ensure traffic is routed to the correct backend */
resource "azurerm_cdn_frontdoor_custom_domain_association" "frontdoor_custom_domain_association" {

  for_each = local.enabled ? {
    for k, v in var.apps : k => v if v.enabled
  } : {}

  cdn_frontdoor_custom_domain_id = azurerm_cdn_frontdoor_custom_domain.frontdoor_custom_domain[each.key].id

  cdn_frontdoor_route_ids = [
    azurerm_cdn_frontdoor_route.frontdoor_route[each.key].id
  ]

  depends_on = [
    null_resource.frontdoor_cname_dns_record
  ]
}

/* Stores TLS certificates (from Key Vault) as Front Door secrets to enable HTTPS for custom domains */
resource "azurerm_cdn_frontdoor_secret" "frontdoor_secret" {

  for_each = {
    for k, v in var.apps : k => v if v.enabled
  }

  name                     = "${var.name}-${each.key}-secret"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile[0].id

  secret {
    customer_certificate {
      key_vault_certificate_id = each.value.cert_secret_id
    }
  }
}