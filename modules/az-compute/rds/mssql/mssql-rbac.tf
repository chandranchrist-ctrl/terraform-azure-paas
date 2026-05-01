resource "azurerm_role_assignment" "sql_kv_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_mssql_server.mssql.identity[0].principal_id
}

resource "azurerm_role_assignment" "sql_kv_keys" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_mssql_server.mssql.identity[0].principal_id
}

resource "azurerm_role_assignment" "sql_kv_cert" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Certificates Officer"
  principal_id         = azurerm_mssql_server.mssql.identity[0].principal_id
}

/* Assigns "Storage Blob Data Contributor" role to SQL Server's Managed Identity;
so it can read/write blobs (used for auditing, vulnerability assessment, backups) */
resource "azurerm_role_assignment" "sql_storage_blob_contributor" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_mssql_server.mssql.identity[0].principal_id
}
