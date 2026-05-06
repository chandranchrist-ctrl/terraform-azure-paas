data "azurerm_client_config" "current" {}

/* Grants owner group full cluster admin access (control plane + Kubernetes RBAC) to manage AKS */
resource "azurerm_role_assignment" "aks_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = var.owner_group_id
}

/* Grants DevOps group write access to deploy and manage workloads in AKS without full admin privileges */
resource "azurerm_role_assignment" "aks_devops" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Writer"
  principal_id         = var.devops_group_id
}

/* Allows AKS managed identity to read secrets from Key Vault (used by workloads via CSI or integrations) */
resource "azurerm_role_assignment" "kv_secrets" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

/* Grants kubelet identity pull access to ACR for downloading container images to cluster nodes */
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

/* Grants AKS control plane identity network permissions to manage resources like load balancers and routing within the subnet */
resource "azurerm_role_assignment" "aks_network_control_plane" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

/* Grants kubelet identity network permissions for node-level operations within the subnet */
resource "azurerm_role_assignment" "aks_network_kubelet" {
  scope                = var.subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}