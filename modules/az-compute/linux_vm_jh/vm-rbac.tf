# RBAC acccess to keyvault
resource "azurerm_role_assignment" "vm_kv_secrets" {
  for_each = azurerm_linux_virtual_machine.vm

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.identity[0].principal_id
}