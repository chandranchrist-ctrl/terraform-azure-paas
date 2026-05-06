/* Configures trusted access by allowing specific Azure services (e.g., Backup) to securely access AKS with defined roles when enabled */
resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "trusted" {

  for_each = var.enable_trusted_access ? var.trusted_access : {}

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id

  name               = each.value.name
  source_resource_id = each.value.source_resource_id
  roles              = each.value.roles
}