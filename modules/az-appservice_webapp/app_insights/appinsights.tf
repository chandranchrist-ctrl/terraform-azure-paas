resource "azurerm_application_insights" "app" {
  name                = var.name
  location            = var.location
  resource_group_name = var.resource_group_name

  application_type = "web"

  workspace_id        = var.workspace_id
  sampling_percentage = var.sampling_percentage
  retention_in_days   = var.retention_in_days
}