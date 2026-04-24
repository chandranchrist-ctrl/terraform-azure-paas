resource "azurerm_private_endpoint" "mssql" {
  count               = var.enable_private_endpoint ? 1 : 0
  name                = "${var.server_name}-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id

  # Connects the Private Endpoint to the Azure SQL Server over a private network (auto-approved)
  private_service_connection {
    name                           = "${var.server_name}-psc"
    private_connection_resource_id = azurerm_mssql_server.mssql.id /* This establishes a private link between your VNet and SQL Server */
    subresource_names              = ["sqlServer"] /* (Other Azure services use different subresource names) */
    is_manual_connection           = false /* false → Automatic approval (same subscription / RBAC access); true  → Manual approval required (cross-tenant / restricted scenarios) */
  }

  # DNS Auto-Integration
  dynamic "private_dns_zone_group" {
    for_each = (
      var.enable_private_endpoint && var.private_dns_zone_id != null
    ) ? [1] : []

    content {
      name                 = "mssql-dns-zone-group"
      private_dns_zone_ids = [var.private_dns_zone_id]
    }
  }
}
