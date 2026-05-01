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

  app_settings = local.app_settings_prod

  site_config {
    always_on           = local.site_config_prod_final.always_on
    http2_enabled       = local.site_config_prod_final.http2_enabled
    minimum_tls_version = local.site_config_prod_final.minimum_tls_version
    use_32_bit_worker   = local.site_config_prod_final.use_32_bit_worker
    websockets_enabled  = local.site_config_prod_final.websockets_enabled

    application_stack {
      node_version = local.site_config_prod_final.node_version
    }

    app_command_line = local.site_config_prod_final.app_command_line

    health_check_path                 = local.site_config_prod_final.health_check_path
    health_check_eviction_time_in_min = local.site_config_prod_final.health_check_eviction_time_in_min

    ftps_state              = local.site_config_prod_final.ftps_state
    scm_minimum_tls_version = local.site_config_prod_final.scm_minimum_tls_version

    remote_debugging_enabled = local.site_config_prod_final.remote_debugging_enabled

    scm_ip_restriction {
      ip_address = local.scm_ip
      action     = local.scm_action
    }

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

  # ---------------- BACKUP ----------------
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
        start_time               = try(var.backup_config.start_time, null)
      }
    }
  }

  # ---------------- LOGS ----------------
  logs {
    application_logs {
      file_system_level = local.logs_config.application_logs.file_system_level

      azure_blob_storage {
        level             = local.logs_config.application_logs.level
        retention_in_days = local.logs_config.application_logs.retention_in_days
        sas_url           = local.logs_config.application_logs.sas_url
      }
    }

    http_logs {
      azure_blob_storage {
        retention_in_days = local.logs_config.http_logs.retention_in_days
        sas_url           = local.logs_config.http_logs.sas_url
      }
    }

    detailed_error_messages = local.logs_config.detailed_error_messages
    failed_request_tracing  = local.logs_config.failed_request_tracing
  }
}

# ---------------- VNET INTEGRATION ----------------
resource "azurerm_app_service_virtual_network_swift_connection" "vnet" {
  app_service_id = azurerm_linux_web_app.app.id
  subnet_id      = var.subnet_id

  depends_on = [
    azurerm_linux_web_app.app
  ]
}

# ---------------- CERTIFICATE ----------------
resource "azurerm_app_service_certificate" "cert" {
  name                = "${var.name}-cert"
  resource_group_name = var.resource_group_name
  location            = var.location

  key_vault_secret_id = var.key_vault_secret_id

  depends_on = [
    azurerm_role_assignment.kv_access,
    azurerm_role_assignment.kv_appservice_access
  ]
}