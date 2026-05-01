# Firewall Rules (IP allow list)
resource "azurerm_mssql_firewall_rule" "allow_ips" {
  for_each = toset(var.allowed_ips)

  name             = replace(each.value, ".", "-")
  server_id        = azurerm_mssql_server.mssql.id
  start_ip_address = each.value
  end_ip_address   = each.value
}

# Outbound Firewall (optional)
resource "azurerm_mssql_outbound_firewall_rule" "outbound" {
  count     = var.enable_outbound_firewall ? 1 : 0
  server_id = azurerm_mssql_server.mssql.id
  name      = "${var.server_name}-outbound"
}

# Security Alert Policy
resource "azurerm_mssql_server_security_alert_policy" "alerts" {
  count = var.enable_security_alerts ? 1 : 0

  resource_group_name = var.resource_group_name
  server_name         = azurerm_mssql_server.mssql.name

  state = var.alerts_state

  email_account_admins = var.email_account_admins
  email_addresses      = var.email_addresses
  retention_days       = var.alert_retention_days
}

# Server Auditing
resource "azurerm_mssql_server_extended_auditing_policy" "server_audit" {
  count             = var.enable_auditing ? 1 : 0
  server_id         = azurerm_mssql_server.mssql.id
  storage_endpoint  = var.audit_storage_endpoint
  retention_in_days = var.audit_retention_days
}

# Database Auditing
resource "azurerm_mssql_database_extended_auditing_policy" "db_audit" {
  count             = var.enable_auditing ? 1 : 0
  database_id       = azurerm_mssql_database.db.id
  storage_endpoint  = var.audit_storage_endpoint
  retention_in_days = var.audit_retention_days
}

# Vulnerability Assessment
resource "azurerm_mssql_server_vulnerability_assessment" "va" {
  count = var.enable_va ? 1 : 0

  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.alerts[0].id

  storage_container_path     = var.va_storage_container
  storage_account_access_key = var.va_storage_key

  recurring_scans {
    enabled                   = var.va_state
    email_subscription_admins = var.email_account_admins
    emails                    = var.email_addresses
  }
}

# Allows the specified VNet subnet to access Azure SQL Server via Service Endpoint (private Azure backbone)
resource "azurerm_mssql_virtual_network_rule" "service_endpoint_app" {
  count = var.enable_service_endpoint_mssql ? 1 : 0

  name      = "${var.server_name}-vnet-se-rule"
  server_id = azurerm_mssql_server.mssql.id
  subnet_id = var.app_subnet_id
}