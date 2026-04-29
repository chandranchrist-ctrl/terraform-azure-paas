############################################
# POD NOT RUNNING (PERSISTENT FAILURE ONLY)
############################################
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "pod_not_running" {

  count = var.enabled ? 1 : 0

  name                = "aks-pod-not-running"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  severity             = 2

  criteria {
    query = <<-KQL
KubePodInventory
| where TimeGenerated > ago(20m)
| where PodStatus !in ("Running", "Succeeded")
| summarize FailCount = count() by Name, Namespace
| where FailCount >= 3
KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Persistent pod failure detected"
}

############################################
# CRASH / FAILED PODS (DEBOUNCED ALERT)
############################################
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "crashloop" {

  count = var.enabled ? 1 : 0

  name                = "aks-crashloop"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  severity             = 1

  criteria {
    query = <<-KQL
KubePodInventory
| where TimeGenerated > ago(20m)
| where PodStatus in ("Failed", "CrashLoopBackOff")
| summarize FailCount = count() by Name, Namespace
| where FailCount >= 2
KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Sustained crash loop detected"
}

############################################
# RESTART SPIKE (ROLLING + THRESHOLD BASED)
############################################
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "restart_spike" {

  count = var.enabled ? 1 : 0

  name                = "aks-pod-restarts"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  severity             = 2

  criteria {
    query = <<-KQL
KubePodInventory
| where TimeGenerated > ago(25m)
| summarize RestartCount = sum(ContainerRestartCount) by Name, Namespace
| where RestartCount >= 10
KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Persistent restart instability detected"
}

############################################
# NODE NOT READY (INFRASTRUCTURE HEALTH)
############################################
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "node_not_ready" {

  count = var.enabled ? 1 : 0

  name                = "aks-node-not-ready"
  resource_group_name = var.resource_group_name
  location            = var.location

  scopes = [var.log_analytics_workspace_id]

  evaluation_frequency = "PT5M"
  window_duration      = "PT15M"
  severity             = 1

  criteria {
    query = <<-KQL
KubeNodeInventory
| where TimeGenerated > ago(15m)
| where Status != "Ready"
| summarize FailCount = count() by Computer
| where FailCount >= 2
KQL

    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"
  }

  action {
    action_groups = [var.action_group_id]
  }

  description = "Node stability issue detected"
}