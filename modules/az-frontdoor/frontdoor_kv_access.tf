/* Retrieves current Terraform identity details (used to assign Key Vault access) */
data "azurerm_client_config" "current" {}

/* Grants Terraform identity permission to read Key Vault secrets (required for accessing certificates used by Front Door) */
resource "azurerm_role_assignment" "kv_cert_access" {
  for_each = local.enabled ? var.apps : {}

  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = data.azurerm_client_config.current.object_id
}