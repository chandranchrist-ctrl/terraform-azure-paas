locals {

  # SCM restriction (VALID placement)
  scm_ip     = "49.37.211.93/32"
  scm_action = "Allow"

  app_settings_common = {
    API_URL = "https://aks-backend-url"
  }

  app_insights_settings = var.enable_app_insights ? {
    APPLICATIONINSIGHTS_CONNECTION_STRING = var.app_insights_connection_string
  } : {}

  # PROD (DEFAULT WEB APP)
  app_settings_prod = merge(
    local.app_settings_common,
    local.app_insights_settings,
    {
      ENVIRONMENT = "prod"
      BASE_URL    = "https://${var.prod_hostname}.${var.domain}"
  })

  # UAT (SLOT)
  app_settings_uat = merge(
    local.app_settings_common,
    local.app_insights_settings,
    {
      ENVIRONMENT = "uat"
      BASE_URL    = "https://${var.uat_hostname}.${var.domain}"
  })


  # SITE CONFIG
  site_config_common = {
    always_on                         = true
    http2_enabled                     = true
    minimum_tls_version               = "1.2"
    use_32_bit_worker                 = false
    node_version                      = "18-lts"
    websockets_enabled                = true
    app_command_line                  = "pm2 serve /home/site/wwwroot --no-daemon"
    health_check_path                 = "/health"
    health_check_eviction_time_in_min = 10
    ftps_state                        = "FtpsOnly"
    scm_minimum_tls_version           = "1.2"
  }

  site_config_uat = {
    detailed_error_messages_enabled = false
    failed_request_tracing_enabled  = false
    remote_debugging_enabled        = false
  }

  site_config_prod = {
    detailed_error_messages_enabled = false
    failed_request_tracing_enabled  = false
    remote_debugging_enabled        = false
  }

  site_config_uat_final  = merge(local.site_config_common, local.site_config_uat)
  site_config_prod_final = merge(local.site_config_common, local.site_config_prod)

  # LOGS
  logs_config = {
    application_logs = {
      file_system_level = "Off"
      level             = "Information"
      retention_in_days = 7
      sas_url           = var.app_logs_sas_url
    }

    http_logs = {
      retention_in_days = 7
      sas_url           = var.http_logs_sas_url
    }

    detailed_error_messages = true
    failed_request_tracing  = true
  }
}