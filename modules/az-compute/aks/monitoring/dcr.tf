resource "azurerm_monitor_data_collection_rule" "aks" {
  name                = var.aks_dcr_name
  location            = var.location
  resource_group_name = var.resource_group_name

  destinations {
    log_analytics {
      name                  = "law"
      workspace_resource_id = var.log_analytics_workspace_id
    }
  }

  data_flow {
    streams      = ["Microsoft-ContainerInsights-Group-Default"]
    destinations = ["law"]
  }

  data_sources {
    extension {
      name           = "containerInsightsExtension"
      extension_name = "ContainerInsights"

      streams = [
        "Microsoft-ContainerInsights-Group-Default"
      ]

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

resource "azurerm_monitor_data_collection_rule_association" "aks" {
  name                    = var.aks_dcr_association
  target_resource_id      = var.aks_id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.aks.id

  depends_on = [
    azurerm_monitor_data_collection_rule.aks
  ]
}