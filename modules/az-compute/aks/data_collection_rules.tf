/* Creates a Data Collection Rule (DCR) for AKS to define what logs/metrics to collect and where to send them (Log Analytics) */
resource "azurerm_monitor_data_collection_rule" "aks" {

  count = var.enable_monitoring ? 1 : 0

  name                = var.aks_dcr_name
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      name                  = "law"
      workspace_resource_id = var.log_analytics_workspace_id
    }
  }

  /* Defines how collected data flows from AKS (stream) to the configured destination (Log Analytics workspace) */
  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["law"] /* Specifies the destination Log Analytics Workspace where AKS logs and metrics will be stored and analyzed */
  }

  /* Defines Container Insights as the data source to collect AKS telemetry like container logs, events, and metrics */
  data_sources {

    /* Configures Container Insights extension with collection rules such as interval, namespace filtering, and what telemetry (events/logs) to collect */
    extension {
      name           = "containerInsightsExtension"
      extension_name = "ContainerInsights"

      /* Specifies which telemetry streams to collect from AKS (default Container Insights stream group) */
      streams = [
        "Microsoft-ContainerInsights-Group-Default"
      ]

      /* Controls how data is collected: frequency (1 min), excludes system namespaces, enables kube events, and disables node-level logs */
      extension_json = jsonencode({
        dataCollectionSettings = {
          interval = "1m"

          namespaceFilteringMode = "Exclude"
          namespaces = [
            "kube-system",
            "gatekeeper-system"
          ]

          enableContainerLogV2 = false
          collectKubeEvents    = true
          collectNodeLogs      = false
        }
      })
    }
  }
}

/* Associates the DCR with the AKS cluster so the defined data collection settings are applied to it */
resource "azurerm_monitor_data_collection_rule_association" "aks" {

  count = var.enable_monitoring ? 1 : 0

  name                    = var.aks_dcr_association
  target_resource_id      = azurerm_kubernetes_cluster.aks.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.aks[0].id
}