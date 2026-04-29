resource "azurerm_linux_web_app_slot" "uat" {
  name           = "uat"
  app_service_id = azurerm_linux_web_app.app.id

  https_only                    = var.https_only
  public_network_access_enabled = var.public_network_access_enabled

  identity {
    type = var.identity_type
  }

  app_settings = local.app_settings_uat

  site_config {
    always_on           = local.site_config_uat_final.always_on
    http2_enabled       = local.site_config_uat_final.http2_enabled
    minimum_tls_version = local.site_config_uat_final.minimum_tls_version
    use_32_bit_worker   = local.site_config_uat_final.use_32_bit_worker
    websockets_enabled  = local.site_config_uat_final.websockets_enabled

    application_stack {
      node_version = local.site_config_uat_final.node_version
    }

    app_command_line = local.site_config_uat_final.app_command_line

    health_check_path                 = local.site_config_uat_final.health_check_path
    health_check_eviction_time_in_min = local.site_config_uat_final.health_check_eviction_time_in_min

    ftps_state              = local.site_config_uat_final.ftps_state
    scm_minimum_tls_version = local.site_config_uat_final.scm_minimum_tls_version

    remote_debugging_enabled = local.site_config_uat_final.remote_debugging_enabled

    scm_ip_restriction {
      ip_address = local.scm_ip
      action     = local.scm_action
    }
  }

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