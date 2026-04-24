# TDE (System or CMK)
resource "azurerm_mssql_server_transparent_data_encryption" "tde" {
  count     = var.enable_tde ? 1 : 0
  server_id = azurerm_mssql_server.mssql.id

  # If CMK enabled → Key Vault Key used
  key_vault_key_id = (var.enable_tde && var.use_cmk_tde) ? var.key_vault_key_id : null
}