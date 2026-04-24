resource "azurerm_private_endpoint" "acr" {
  count = var.enable_private_endpoint ? 1 : 0

  name                = "${var.acr_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  private_service_connection {
    name                           = "${var.acr_name}-psc"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  dynamic "private_dns_zone_group" {
    for_each = var.private_dns_zone_id != null ? [1] : []

    content {
      name                 = "acr-dns-zone-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}