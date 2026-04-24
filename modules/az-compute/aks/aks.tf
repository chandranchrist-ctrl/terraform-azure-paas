resource "azurerm_kubernetes_cluster" "aks" {

  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags


  kubernetes_version = var.kubernetes_version
  sku_tier           = var.sku_tier

  dns_prefix                 = var.private_cluster_enabled ? null : var.dns_prefix
  dns_prefix_private_cluster = var.private_cluster_enabled ? var.dns_prefix_private_cluster : null

  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = var.private_dns_zone_id

  automatic_upgrade_channel = var.automatic_upgrade_channel
  node_os_upgrade_channel   = var.node_os_upgrade_channel

  dynamic "api_server_access_profile" {
    for_each = var.api_server_access_profile != null ? [var.api_server_access_profile] : []

    content {
      authorized_ip_ranges = api_server_access_profile.value.authorized_ip_ranges
    }
  }

  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []

    content {
      balance_similar_node_groups = auto_scaler_profile.value.balance_similar_node_groups
    }
  }

  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.aad_rbac.enabled ? [1] : []

    content {
      tenant_id          = data.azurerm_client_config.current.tenant_id
      azure_rbac_enabled = var.aad_rbac.azure_rbac_enabled
    }
  }

  role_based_access_control_enabled = var.role_based_access_control_enabled

  disk_encryption_set_id = var.disk_encryption_set_id

  http_application_routing_enabled = var.http_application_routing_enabled

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []

    content {
      type = identity.value.type
    }
  }

  dynamic "kubelet_identity" {
    for_each = length(keys(var.kubelet_identity)) > 0 ? [var.kubelet_identity] : []

    content {
      client_id                 = try(kubelet_identity.value.client_id, null)
      object_id                 = try(kubelet_identity.value.object_id, null)
      user_assigned_identity_id = try(kubelet_identity.value.user_assigned_identity_id, null)
    }
  }

  dynamic "linux_profile" {
    for_each = var.enable_ssh ? [1] : []

    content {
      admin_username = var.admin_username

      ssh_key {
        key_data = data.azurerm_key_vault_secret.ssh_public_key.value
      }
    }
  }

  local_account_disabled = var.local_account_disabled

  dynamic "maintenance_window" {
    for_each = var.enable_maintenance_window ? [1] : []

    content {
      allowed {
        day   = "Sunday"
        hours = [1, 2, 3]
      }
    }
  }
  dynamic "maintenance_window_auto_upgrade" {
    for_each = var.enable_maintenance_window ? [1] : []

    content {
      frequency = "Weekly"
      interval  = 1
      duration  = 4
    }
  }

  dynamic "maintenance_window_node_os" {
    for_each = var.enable_maintenance_window ? [1] : []

    content {
      frequency = "Weekly"
      interval  = 1
      duration  = 4
    }
  }

  dynamic "microsoft_defender" {
    for_each = var.enable_defender ? [1] : []

    content {
      log_analytics_workspace_id = var.defender_workspace_id
    }
  }

  dynamic "monitor_metrics" {
    for_each = var.monitor_metrics ? [1] : []

    content {}
  }

  dynamic "network_profile" {
    for_each = var.network_profile != null ? [var.network_profile] : []

    content {
      network_plugin = network_profile.value.network_plugin
      network_policy = network_profile.value.network_policy
    }
  }

  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled

  dynamic "oms_agent" {
    for_each = var.enable_oms_agent ? [1] : []

    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "storage_profile" {
    for_each = var.storage_profile != null ? [var.storage_profile] : []

    content {
      blob_driver_enabled = try(storage_profile.value.blob_driver_enabled, false)
      disk_driver_enabled = try(storage_profile.value.disk_driver_enabled, true)
      file_driver_enabled = try(storage_profile.value.file_driver_enabled, true)
    }
  }
  support_plan = var.support_plan

  run_command_enabled = var.run_command_enabled

  default_node_pool {
    name           = var.default_node_pool.name
    vm_size        = var.default_node_pool.vm_size
    vnet_subnet_id = var.default_node_pool.vnet_subnet_id

    auto_scaling_enabled = var.default_node_pool.auto_scaling_enabled

    node_count = var.default_node_pool.auto_scaling_enabled ? null : var.default_node_pool.node_count

    min_count = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.min_count : null
    max_count = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.max_count : null
  }
}