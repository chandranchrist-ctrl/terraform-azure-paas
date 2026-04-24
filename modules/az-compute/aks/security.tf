resource "azurerm_kubernetes_cluster_trusted_access_role_binding" "trusted" {

  for_each = var.enable_trusted_access ? var.trusted_access : {}

  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id

  name               = each.value.name
  source_resource_id = each.value.source_resource_id
  roles              = each.value.roles
}

resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}