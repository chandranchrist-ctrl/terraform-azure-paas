# defines routing rules in Azure Front Door that map incoming requests from the endpoint to the correct origin group based on domain and path patterns
resource "azurerm_cdn_frontdoor_route" "frontdoor_route" {

  for_each = local.enabled ? {
    for k, v in var.apps : k => v if v.enabled
  } : {}

  name                      = "${var.name}-${each.key}-route"
  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint[0].id

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group[each.key].id

  cdn_frontdoor_origin_ids = concat(
    [azurerm_cdn_frontdoor_origin.frontdoor_origin_primary[each.key].id],
    var.apps[each.key].enable_dr ? [azurerm_cdn_frontdoor_origin.frontdoor_origin_secondary[each.key].id] : []
  )

  supported_protocols = ["Http", "Https"]
  patterns_to_match   = ["/*"]

  forwarding_protocol    = "HttpsOnly"
  link_to_default_domain = false
}