resource "azurerm_role_assignment" "aks_kv_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}