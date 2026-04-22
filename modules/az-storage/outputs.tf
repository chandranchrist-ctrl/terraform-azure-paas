output "storage_account_id" {
  value = azurerm_storage_account.storage_account.id
}

output "storage_account_name" {
  value = azurerm_storage_account.storage_account.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.storage_account.primary_blob_endpoint
}

output "primary_access_key" {
  value     = azurerm_storage_account.storage_account.primary_access_key
  sensitive = true
}

output "container_names" {
  value = keys(azurerm_storage_container.containers)
}

output "container_urls" {
  value = {
    for k, v in azurerm_storage_container.containers :
    k => "${azurerm_storage_account.storage_account.primary_blob_endpoint}/${v.name}"
  }
}