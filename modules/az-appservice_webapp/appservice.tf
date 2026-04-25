resource "azurerm_linux_web_app" "app" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  service_plan_id               = var.app_service_plan_id
  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled

  identity {
    type = var.identity_type
  }

  site_config {
    always_on           = local.site_config_common.always_on
    http2_enabled       = local.site_config_common.http2_enabled
    minimum_tls_version = local.site_config_common.minimum_tls_version

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions

      content {
        name       = ip_restriction.value.name
        ip_address = ip_restriction.value.ip_address
        priority   = ip_restriction.value.priority
        action     = ip_restriction.value.action
      }
    }
  }

  # -----------------------------
  # BACKUP
  # -----------------------------
  dynamic "backup" {
    for_each = var.backup_config.enabled ? [1] : []

    content {
      name                = "appservice-backup"
      storage_account_url = var.backup_config.storage_account_url
      enabled             = true

      schedule {
        frequency_interval       = var.backup_config.frequency_interval
        frequency_unit           = var.backup_config.frequency_unit
        retention_period_days    = var.backup_config.retention_period_days
        keep_at_least_one_backup = var.backup_config.keep_at_least_one_backup

        start_time = try(var.backup_config.start_time, null)
      }
    }
  }
}

resource "azurerm_app_service_virtual_network_swift_connection" "vnet" {
  app_service_id = azurerm_linux_web_app.app.id
  subnet_id      = var.subnet_id
}

resource "azurerm_app_service_certificate" "cert" {
  name                = "${var.name}-cert"
  resource_group_name = var.resource_group_name
  location            = var.location

  key_vault_secret_id = var.key_vault_secret_id
}