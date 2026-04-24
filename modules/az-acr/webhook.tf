resource "azurerm_container_registry_webhook" "webhook" {
  count = var.enable_webhook ? 1 : 0

  name                = "${var.acr_name}-webhook"
  resource_group_name = var.resource_group_name
  registry_name       = azurerm_container_registry.acr.name
  location            = var.location

  service_uri = var.webhook_uri

  actions = ["push"]
  status  = "enabled"
}