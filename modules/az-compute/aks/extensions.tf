/* Deploys optional AKS extensions dynamically (e.g., monitoring, security, GitOps) based on input map, enabling additional cluster capabilities */
resource "azurerm_kubernetes_cluster_extension" "ext" {

  for_each = var.extensions != null ? var.extensions : {}

  name           = each.key
  cluster_id     = azurerm_kubernetes_cluster.aks.id
  extension_type = each.value.type
}