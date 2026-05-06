/* Filters and stores only enabled applications to ensure Front Door resources are created only for active apps */
locals {
  enabled_apps = {
    for k, v in var.apps : k => v
    if v.enabled
  }
}

/* Creates origin groups for each enabled app, defining load balancing and health probe settings for backend endpoints */
resource "azurerm_cdn_frontdoor_origin_group" "frontdoor_origin_group" {

  for_each = local.enabled_apps

  name                     = "${var.name}-${each.key}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.frontdoor_profile[0].id

  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
  }

  health_probe {
    interval_in_seconds = 120
    protocol            = "Https"
    request_type        = "HEAD"
    path                = "/"
  }
}

/* Defines primary backend origin for each app with highest priority to serve traffic under normal conditions */
resource "azurerm_cdn_frontdoor_origin" "frontdoor_origin_primary" {

  for_each = local.enabled_apps

  name = "${var.name}-${each.key}-primary"

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group[each.key].id

  host_name = each.value.backend_primary

  http_port  = 80
  https_port = 443

  enabled = true

  certificate_name_check_enabled = false

  priority = 1
  weight   = 1000
}

/* Defines optional secondary (DR) backend origin for failover, used when primary origin becomes unhealthy */
resource "azurerm_cdn_frontdoor_origin" "frontdoor_origin_secondary" {

  for_each = {
    for k, v in local.enabled_apps : k => v
    if v.enable_dr == true
  }

  name = "${var.name}-${each.key}-secondary"

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.frontdoor_origin_group[each.key].id

  host_name = each.value.backend_secondary

  http_port  = 80
  https_port = 443

  enabled = true

  certificate_name_check_enabled = false

  priority = 2
  weight   = 500
}