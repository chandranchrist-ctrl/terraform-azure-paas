resource "azurerm_kubernetes_cluster_deployment_safeguard" "safe" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  level                 = var.deployment_safeguard.level
}