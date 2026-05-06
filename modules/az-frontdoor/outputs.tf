output "frontdoor_endpoint_hostname" {
  value = try(azurerm_cdn_frontdoor_endpoint.frontdoor_endpoint[0].host_name, null)
}

output "frontdoor_profile_id" {
  value = try(azurerm_cdn_frontdoor_profile.frontdoor_profile[0].id, null)
}