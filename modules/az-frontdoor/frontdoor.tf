locals {
  enabled = var.enable_frontdoor
}

# creates the Azure Front Door profile which acts as the global configuration container for endpoints, routing rules, domains, and WAF policies
resource "azurerm_cdn_frontdoor_profile" "frontdoor_profile" {
  count               = local.enabled ? 1 : 0
  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  tags                = var.tags
}

# creates the Front Door endpoint which is the public entry hostname under Front Door used to receive and route traffic
resource "azurerm_cdn_frontdoor_endpoint" "frontdoor_endpoint" {
  count = local.enabled ? 1 : 0
  name  = "${var.name}-endpoint"

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile[0].id
}
