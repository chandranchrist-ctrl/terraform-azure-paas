/* Defines a custom ACR role with data-plane permissions to push (write) and pull (read) container images, scoped only to this registry for controlled admin access */
resource "azurerm_role_definition" "acr_admin_custom" {
  name        = "acr-admin-custom"
  scope       = azurerm_container_registry.acr.id
  description = "Custom ACR Admin role with push, pull, delete permissions"

  permissions {
    actions = []

    data_actions = [
      # Image push & pull
      "Microsoft.ContainerRegistry/registries/repositories/content/read",
      "Microsoft.ContainerRegistry/registries/repositories/content/write",
    ]
  }

  assignable_scopes = [
    azurerm_container_registry.acr.id
  ]
}