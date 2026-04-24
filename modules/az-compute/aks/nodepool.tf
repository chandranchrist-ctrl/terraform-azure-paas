resource "azurerm_kubernetes_cluster_node_pool" "extra" {

  for_each = var.node_pools

  name                  = each.value.name
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id

  vm_size = each.value.vm_size

  auto_scaling_enabled = each.value.auto_scaling_enabled

  node_count = each.value.auto_scaling_enabled ? null : each.value.node_count

  min_count = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count = each.value.auto_scaling_enabled ? each.value.max_count : null

  vnet_subnet_id = var.default_node_pool.vnet_subnet_id
}