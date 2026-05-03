# Get current user (bootstrap)
data "azuread_client_config" "current" {}

# Common members (avoid duplication)
locals {
  admin_members = [
    data.azuread_client_config.current.object_id
  ]

  devops_members = []
}

# Centralized AD groups
module "access" {
  source = "../../modules/az-ad-access"

  groups = {
    # ACR
    acr_owner = {
      name    = "acr-owner"
      members = local.admin_members
    }

    acr_admins = {
      name    = "acr-admins"
      members = local.admin_members
    }

    acr_devops = {
      name    = "acr-devops"
      members = local.devops_members
    }

    # AKS
    aks_admins = {
      name    = "aks-admins"
      members = local.admin_members
    }

    aks_devops = {
      name    = "aks-devops"
      members = local.devops_members
    }

    # Key Vault
    kv_admins = {
      name    = "kv-admins"
      members = local.admin_members
    }

    kv_devops = {
      name    = "kv-devops"
      members = local.devops_members
    }

    # App Service
    app_admins = {
      name    = "appservice-admins"
      members = local.admin_members
    }

    app_devops = {
      name    = "appservice-devops"
      members = local.devops_members
    }

    law_admins = {
      name    = "law-admins"
      members = local.admin_members
    }

    law_devops = {
      name    = "law-devops"
      members = local.devops_members
    }
  }
}