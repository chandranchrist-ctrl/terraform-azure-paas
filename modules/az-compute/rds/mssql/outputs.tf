output "server_id" {
  value = azurerm_mssql_server.mssql.id
}

output "server_fqdn" {
  value = azurerm_mssql_server.mssql.fully_qualified_domain_name
}

output "db_id" {
  value = azurerm_mssql_database.db.id
}