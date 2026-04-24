resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  admin_enabled = var.admin_enabled

  public_network_access_enabled = var.public_network_access_enabled

  anonymous_pull_enabled = var.anonymous_pull_enabled

  export_policy_enabled = var.export_policy_enabled

  tags = var.tags

  identity {
    type = var.identity_type
  }

  # PREMIUM ONLY FEATURE
  data_endpoint_enabled   = var.enable_data_endpoint
  zone_redundancy_enabled = var.zone_redundancy_enabled

  # Retention
  retention_policy_in_days = var.enable_retention_policy ? var.retention_days : null

  dynamic "encryption" {
    for_each = var.enable_cmk ? [1] : []
    content {
      key_vault_key_id = var.acr_cmk_id
    }
  }

  network_rule_set {
    default_action = "Deny"

    ip_rule = [
      for ip in var.allowed_ips : {
        action   = "Allow"
        ip_range = ip
      }
    ]
  }

  dynamic "georeplications" {
    for_each = var.enable_georeplication ? var.replica_locations : []

    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.enable_cmk && var.sku != "Premium")
      error_message = "CMK cannot be enabled unless SKU is Premium."
    }
  }

}