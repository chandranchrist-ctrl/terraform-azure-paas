resource "azurerm_service_plan" "appserviceplan" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  os_type  = var.os_type
  sku_name = var.sku_name

  zone_balancing_enabled = var.zone_balancing_enabled
}