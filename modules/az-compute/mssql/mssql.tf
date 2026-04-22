# MSSQL Server
resource "azurerm_mssql_server" "mssql" {
  name                = var.server_name
  resource_group_name = var.resource_group_name
  location            = var.location

  version                      = var.server_version
  administrator_login          = local.sql_creds.username
  administrator_login_password = local.sql_creds.password

  minimum_tls_version = "1.2"

  public_network_access_enabled = var.enable_public_access

  tags = var.tags

  identity {
    type = "SystemAssigned"
  }

  dynamic "azuread_administrator" {
    for_each = var.enable_aad_admin ? [1] : []

    content {
      login_username = var.azuread_admin_username
      object_id      = var.azuread_admin_object_id
      tenant_id      = data.azurerm_client_config.current.tenant_id
    }
  }
}

# MSSQL Database
resource "azurerm_mssql_database" "db" {
  name      = var.database_name
  server_id = azurerm_mssql_server.mssql.id

  collation    = var.collation
  license_type = "LicenseIncluded"
  sku_name     = var.sku_name
  max_size_gb  = var.max_size_gb



  zone_redundant = var.zone_redundant

  read_scale = var.read_scale

  storage_account_type = var.storage_account_type

  short_term_retention_policy {
    retention_days = var.short_term_retention_days
  }

  dynamic "long_term_retention_policy" {
    for_each = var.enable_long_term_retention ? [1] : []

    content {
      weekly_retention  = var.ltr_weekly_retention
      monthly_retention = var.ltr_monthly_retention
      yearly_retention  = var.ltr_yearly_retention
      week_of_year      = var.ltr_week_of_year
    }
  }

  tags = var.tags
}


