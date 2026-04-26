# Pod Not Running
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_not_running" {
  name                = "aks-pod-not-running"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  severity             = 2

  criteria {
    query = <<-KQL
      KubePodInventory
      | where PodStatus !in ("Running", "Succeeded")
    KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Pod is not running"
}

# CrashLoopBackOff
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "crashloop" {
  name                = "aks-crashloop"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  severity             = 1

  criteria {
    query = <<-KQL
      KubePodInventory
      | where ContainerStatus has "CrashLoopBackOff"
    KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Pod in CrashLoopBackOff"
}

# Restart Spike
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "restart_spike" {
  name                = "aks-pod-restarts"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  severity             = 2

  criteria {
    query = <<-KQL
      KubePodInventory
      | summarize RestartCount = sum(ContainerRestartCount) by PodName, Namespace
      | where RestartCount > 5
    KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Pod restart spike detected"
}

# Node Not Ready
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "node_not_ready" {
  name                = "aks-node-not-ready"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"
  severity             = 1

  criteria {
    query = <<-KQL
      KubeNodeInventory
      | where Status != "Ready"
    KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Node is not Ready"
}