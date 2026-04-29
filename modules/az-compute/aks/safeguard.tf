resource "azurerm_kubernetes_cluster_deployment_safeguard" "safe" {
  count = var.deployment_safeguard != null ? 1 : 0

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  level                 = var.deployment_safeguard.level
}