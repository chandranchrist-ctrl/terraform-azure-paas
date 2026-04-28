terraform {
  # backend "azurerm" {
  #   resource_group_name  = "tfstate-rg"
  #   storage_account_name = "uattfstatebookshop01"
  #   container_name       = "tfstate"
  #   key                  = "staging.terraform.tfstate"
  # }

  backend "local" {}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.67.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

# Local values for environment-specific naming
locals {
  env      = "uat"
  workload = "bookshop"
}

# Reusable module to create Resource Group
module "rg" {
  source = "../../modules/az-rg"

  env = local.env

  # Input Variables
  resource_group_name     = "${local.env}-rg"
  resource_group_location = "centralindia"

  tags = {
    environment = "uat"
    # project     = "webapp"
    # owner       = "devops"
  }
}


# Network module for hub-spoke setup (VNet, Subnet, NSG, NSG Rules)
module "virtual_network" {
  source = "../../modules/az-network"

  env      = local.env
  workload = local.workload

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  /* Controls internet access from subnet: true = allows default outbound internet, false = blocks unless explicitly configured (e.g., NAT/Firewall) */
  default_outbound_access_enabled = true

  # VNet CIDR
  /* {VNet key = hub\spoke} must match the corresponding key in subnet_address_space to map subnets to the correct VNet */
  vnet_address_space = {
    hub = ["10.0.0.0/16"]
    fe  = ["10.1.0.0/16"]
    be  = ["172.21.0.0/16"]
  }

  # Subnet CIDR
  /* {Subnet key = AzureFirewallSubnet\app} must align with the VNet key to ensure subnets are created within the correct VNet */
  subnet_address_space = {
    hub = {
      AzureBastionSubnet = {
        cidr = ["10.0.0.128/26"]
        tags = { type = "infra" }
      }

      jumpbox = {
        cidr = ["10.0.1.0/27"]
        tags = { type = "workload" }
      }
    }

    fe = {
      app = {
        cidr = ["10.1.1.64/26"]
        tags = { type = "workload" }
      }
    }

    be = {
      aks = {
        cidr = ["172.21.0.0/22"]
        tags = { type = "workload" }
      }
      db = {
        cidr = ["172.21.4.0/26"]
        tags = { type = "workload" }
      }
      private_endpoint = {
        cidr = ["172.21.5.0/27"]
        tags = { type = "infra" }
      }
    }
  }
}


# Network - VNet Peering
module "vnet_peering" {
  source = "../../modules/az-vnet-peering"


  peerings = {
    hub_to_fe = {
      name              = "${local.env}-hub-to-fe"
      resource_group    = module.rg.resource_group_name
      vnet_name         = module.virtual_network.vnets["hub"].name
      remote_vnet_id    = module.virtual_network.vnets["fe"].id
      allow_vnet_access = true
      # Enables transit traffic via Hub (Spoke → Hub → Spoke)
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },
    fe_to_hub = {
      name              = "${local.env}-fe-to-hub"
      resource_group    = module.rg.resource_group_name
      vnet_name         = module.virtual_network.vnets["fe"].name
      remote_vnet_id    = module.virtual_network.vnets["hub"].id
      allow_vnet_access = true
      # Enables transit traffic via Hub (Spoke → Hub → Spoke)
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },
    hub_to_be = {
      name              = "${local.env}-hub-to-be"
      resource_group    = module.rg.resource_group_name
      vnet_name         = module.virtual_network.vnets["hub"].name
      remote_vnet_id    = module.virtual_network.vnets["be"].id
      allow_vnet_access = true
      # Enables transit traffic via Hub (Spoke → Hub → Spoke)
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },
    be_to_hub = {
      name              = "${local.env}-be-to-hub"
      resource_group    = module.rg.resource_group_name
      vnet_name         = module.virtual_network.vnets["be"].name
      remote_vnet_id    = module.virtual_network.vnets["hub"].id
      allow_vnet_access = true
      # Enables transit traffic via Hub (Spoke → Hub → Spoke)
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },
    fe_to_be = {
      name              = "${local.env}-fe-to-be"
      resource_group    = module.rg.resource_group_name
      vnet_name         = module.virtual_network.vnets["fe"].name
      remote_vnet_id    = module.virtual_network.vnets["be"].id
      allow_vnet_access = true
      # Enables transit traffic via Hub (Spoke → Hub → Spoke)
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },
    be_to_fe = {
      name              = "${local.env}-be-to-fe"
      resource_group    = module.rg.resource_group_name
      vnet_name         = module.virtual_network.vnets["be"].name
      remote_vnet_id    = module.virtual_network.vnets["fe"].id
      allow_vnet_access = true
      # Enables transit traffic via Hub (Spoke → Hub → Spoke)
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  }

  /* {depends_on} ensures VNet creation is completed before establishing peering */
  depends_on = [module.virtual_network]
}

# Network - Private DNS
module "private_dns" {
  source = "../../modules/az-dns/private"

  resource_group_name = module.rg.resource_group_name

  /* list of private DNS zones to create */
  zones = [
    "privatelink.database.windows.net",
    "privatelink.blob.core.windows.net",
    "privatelink.vaultcore.azure.net",
    "privatelink.azurecr.io"
  ]

  /* VNets to link with DNS zones for name resolution */
  vnet_ids = [
    module.virtual_network.vnets["hub"].id,
    module.virtual_network.vnets["fe"].id,
    module.virtual_network.vnets["be"].id
  ]

  /* Alternative Declaration {vnet_ids}: dynamically fetch all VNet IDs from module output;
Use when you want to link DNS to all VNets automatically (no manual selection needed);
Not needed if only specific VNets (e.g., hub/spoke) should be linked */

  /*   vnet_ids = [
    for v in module.virtual_network.vnets : v.id
  ] */

  depends_on = [
    module.virtual_network
   ]
}

module "diag_storage_account" {
  source = "../../modules/az-storage"

  storage_account_name = var.diag_storage_account_name

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  account_kind          = "StorageV2" /* StorageV2, Storage, BlobStorage, FileStorage, BlockBlobStorage */
  account_tier          = "Standard" /* Standard or Premium */
  replication_type      = "LRS" /* LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS */
  dns_endpoint_type     = "Standard" /* Standard or MicrosoftEndpointsOnly */
  public_network_access = true /* disable public endpoint for enhanced security; access will be via private endpoint or service endpoints from allowed subnets */

  # retention / governance
  blob_versioning_enabled         = false /* enable blob versioning for data protection and recovery */
  blob_delete_retention_days      = 1 /* enable soft delete for blobs with a retention period of 1 day; adjust as needed */
  container_delete_retention_days = 1 /* enable soft delete for containers with a retention period of 1 day; adjust as needed */

  # network rules
  /* Only allow private network access (recommended) */
  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["app"],
    module.virtual_network.subnet_lookup["db"]
  ]

  allowed_ip_rules = ["49.37.211.93"] /* allows access from specific public IPs */

  # Lifecycle Enabled
  /* lifecycle_rules = [] - lifecycle NOT needed → empty or omitted */
  lifecycle_rules = [
    {
      name   = "diag-cleanup"
      prefix = ["bootdiagnostics", "insights-logs"]
      days   = 1
    }
  ]

  depends_on = [ 
    module.virtual_network
   ]  
}

# Storage - Storage Account{for diagnostics}
module "appservice_storage_account" {
  source = "../../modules/az-storage"

  storage_account_name = var.appservice_storage_account_name

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  account_kind          = "StorageV2" /* StorageV2, Storage, BlobStorage, FileStorage, BlockBlobStorage */
  account_tier          = "Standard" /* Standard or Premium */
  replication_type      = "LRS" /* LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS */
  dns_endpoint_type     = "Standard" /* Standard or MicrosoftEndpointsOnly */
  public_network_access = true /* disable public endpoint for enhanced security; access will be via private endpoint or service endpoints from allowed subnets */

  # retention / governance
  blob_versioning_enabled         = false /* enable blob versioning for data protection and recovery */
  blob_delete_retention_days      = 1 /* enable soft delete for blobs with a retention period of 1 day; adjust as needed */
  container_delete_retention_days = 1 /* enable soft delete for containers with a retention period of 1 day; adjust as needed */

  # network rules
  /* Only allow private network access (recommended) */
  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["app"]
  ]

  allowed_ip_rules = ["49.37.211.93"] /* allows access from specific public IPs */

  /* List of storage containers to create inside the storage account (each item becomes one container) */
  containers = [
    "app-logs",
    "http-logs",
    "backups"
  ]

  enable_sas = true

  # Lifecycle Enabled
  /* lifecycle_rules = [] - lifecycle NOT needed → empty or omitted */
  lifecycle_rules = [
    {
      name   = "app-logs-retention"
      prefix = ["app-logs/"]
      days   = 1
    },
    {
      name   = "http-logs-retention"
      prefix = ["http-logs/"]
      days   = 1
    },
    {
      name   = "backup-retention"
      prefix = ["backups/"]
      days   = 1
    }
  ]

  depends_on = [ 
    module.virtual_network
   ]
}

# Storage - Storage Account{for mssql VA & Audit}
module "mssql_storage_account" {
  source = "../../modules/az-storage"

  storage_account_name = var.mssql_storage_account_name

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name

  tags = merge(module.rg.tags, {
    purpose = "mssql-logging"
  })

  account_kind          = "StorageV2"
  account_tier          = "Standard"
  replication_type      = "LRS"
  dns_endpoint_type     = "Standard"
  public_network_access = true

  allowed_ip_rules = ["49.37.211.93"]

  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["db"]
  ]

  blob_versioning_enabled = false

  blob_delete_retention_days      = 1
  container_delete_retention_days = 1

  /* List of storage containers to create inside the storage account (each item becomes one container) */
  containers = [
    "sqldbauditlogs",
    "sql-va-logs"
  ]

  # Lifecycle Enabled (multi-rule)
  lifecycle_rules = [
    {
      name   = "audit-retention"
      prefix = ["sqldbauditlogs"]
      days   = 1
    },
    {
      name   = "va-retention"
      prefix = ["sql-va-logs"]
      days   = 1
    }
  ]

  depends_on = [ 
    module.virtual_network
   ]

}

# Security - Key Vault
module "key_vault" {
  source = "../../modules/az-keyvault"

  name = var.key_vault_name /* "${local.env}-${local.workload}-kv-17" = Key Vault names must be globally unique across Azure. */

  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  /* false = uses access policies, true = uses RBAC */
  rbac_authorization_enabled = true

  /* true = creates access for current user, false = no access policy */
  create_access_policy_me = false

  /* standard = basic features, premium = supports HSM-backed keys */
  sku_name = "standard" # Standard or Premium

  soft_delete_retention_days = 7 /* days to retain deleted items (7–90) */
  purge_protection_enabled   = false /* true = prevents permanent deletion, false = allows purge */

  enabled_for_deployment          = true /* true = allows VM deployment access */
  enabled_for_template_deployment = true /* true = allows ARM template access */

  enable_private_endpoint = true
  private_subnet_id       = module.virtual_network.subnet_lookup["private_endpoint"]
  private_dns_zone_id     = module.private_dns.zone_ids["privatelink.vaultcore.azure.net"]

  public_network_access_enabled = true /* true = allows public access, false = private only */

  network_acls_default_action = "Deny" /* Deny = block all except allowed, Allow = open access */
  allowed_ip_ranges           = ["49.37.211.93/32"] /* allowed public IPs */

  /*   For subnet restrictions, ensure the subnets exist and are correctly referenced.
  service_endpoints = ["Microsoft.KeyVault"] is enabled on those subnets in the network module. */
  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["app"],
    module.virtual_network.subnet_lookup["aks"],
    module.virtual_network.subnet_lookup["db"]
  ]

  # Security - SSH Key
  /* stores SSH public key as secret */
  ssh_secret_name = "linux-ssh-public-key"
  ssh_public_key  = file("${path.module}/ssh/id_rsa.pub")

  # Security - Secrets
  /* key-value secrets stored in Key Vault */
  secrets = {
    localadmin-credentials = jsonencode({
      admin-username = "HBAdmin",
      admin-password = "Qwerty123!",
    })

    mssql-credentials = jsonencode({
      username = "sqladmin"
      password = "SQLP@ssword!23!"
    })

    godaddy-apikey = jsonencode({
      Key    = "hkHptCfQoPVe_S64u3fVz88NYAZwGPuE9ir"
      Secret = "QLsAdAfb4pLq4VsVMQ2gFT"
    })
  }

  # Security - Certificates
  /* imports certificates from PFX */
  certificates = [
    {
      name     = "wildcard-cert"
      pfx_path = "./certs/certificate.pfx"
      password = "Y12345Z"
    }
  ]

  # Monitoring - Diagnostics
  audit_storage_account_name = module.diag_storage_account.storage_account_name
  audit_storage_account_rg   = module.rg.resource_group_name

  # depends_on ensures storage account is created before enabling diagnostics
  depends_on = [
    module.diag_storage_account,
    module.private_dns,
    module.virtual_network
  ]
}

# Network Security - Azure Bastion
# module "bastion" {
#   source = "../../modules/az-bastion"

#   env = local.env

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   subnet_id = module.virtual_network.subnet_lookup["AzureBastionSubnet"] /* dedicated Bastion subnet */

#   sku = "Standard" /* Basic or Standard (Standard = more features) */

#   tunneling_enabled  = true /* true = allows native client (SSH/RDP) via Bastion */
#   ip_connect_enabled = true /* true = connect using private IP */
#   copy_paste_enabled = true /* true = enable clipboard */
#   file_copy_enabled  = true /* true = allow file transfer */

#   zones = null /* null = no zone redundancy, ["1","2","3"] = zone redundant */

#   kerberos_enabled = false /* true = enable Kerberos auth, false = disabled */

#   depends_on = [
#     module.virtual_network
#    ]
# }


# Linux VM Deployment Module
/* Creates one or more Linux VMs with networking, disks, identity, and optional integrations (LB, ASG, Backup, Diagnostics) */
module "jumpbox_linux_vm" {
  source = "../../modules/az-compute/linux_vm_jh"

  env      = local.env
  workload = local.workload

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  vm_name  = "${local.env}-jumpbox-lnx01"
  vm_count = 1

  vm_size   = "Standard_B2s_v2"
  image_sku = "18.04-LTS"

  subnet_id = module.virtual_network.subnet_lookup["jumpbox"]

  private_ip_allocation = "Dynamic"

  os_disk_storage_type = "Standard_LRS"
  os_disk_size_gb      = 127

  enable_public_ip = true /* true  → VM gets public IP (direct internet access) */

  enable_availability_set = false /* true  → VMs distributed across fault/update domains (HA within region) */

  availability_set_name = "biztalk-avset"

  zones = null /* ["1","2","3"] → zone-based high availability; null/empty → no zone (regional deployment) */

  enable_boot_diagnostics               = true
  boot_diagnostics_mode                 = "existing" /* "none", "existing", or "create" */
  boot_diagnostics_storage_account_name = module.diag_storage_account.storage_account_name

  /*Fetches admin credentials from Key Vault instead of hardcoding
  Helps secure VM username/password */
  key_vault_id                       = module.key_vault.key_vault_id # change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password
  localadmin_credentials_secret_name = "localadmin-credentials"

  # Authentication method
  /* true  → only SSH login (recommended for production)
   false → password + SSH allowed */
  disable_password_authentication = false

  ssh_public_key_secret_name = "linux-ssh-public-key" /* SSH public key stored in Key Vault */

  enable_asg = false

  # enable_lb = false                                         /* true  → attaches VM NICs to Load Balancer backend pool */

  # Scenario 1: Existing LB
  # lb_name              = "existing-lb-name"
  # lb_backend_pool_name = "backend-pool-name"

  # Scenario 2: New LB scenario (created in same Terraform)
  # lb_backend_pool_id = module.loadbalancer.backend_pool_id        # null

  # Data disks (optional)
  /*
  data_disks = [
    {
      # size_gb = 128
      # lun     = 0
      # caching = "ReadWrite"
      # storage_type = "Standard_LRS"
    }
  ] 
  */

  # Backup configuration
  enable_backup = false /* true  → enables VM backup using Recovery Services Vault */

  # Recovery Serivce Vault Configuration
  recovery_services_vault_name = "existing-rsv"
  backup_policy_vm             = "existing-policy"

  # Ensure dependencies are created before VM
  depends_on = [
    module.key_vault,
    module.diag_storage_account,
    module.virtual_network
  ]
}

# module "mssql" {
#   source = "../../modules/az-compute/rds/mssql"

#   env      = local.env
#   workload = local.workload

#   # Basic Identity
#   server_name   = "${local.env}-${local.workload}-sql1"
#   database_name = "${local.env}_${local.workload}_db1"

#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   # Server Config
#   server_version = "12.0"

#   /* Pricing tier
#      Examples:
#      Basic → dev/test
#      S0/S1 → small workloads
#      GP_* → General Purpose (recommended)
#      BC_* → Business Critical (high IO + HA) */
#   sku_name = "Basic"

#   max_size_gb = 2

#   # Collation for sorting/comparison
#   collation = "SQL_Latin1_General_CP1_CI_AS"

#   # Zone redundancy (multi-zone HA)
#   zone_redundant = false

#   # Read scale (read-only replicas)
#   read_scale = false

#   # Storage type
#   # Local → cheaper
#   # Geo → geo-redundant backup
#   storage_account_type = "Local"

#   storage_account_id = module.mssql_storage_account.storage_account_id

#   # Authentication (from Key Vault)
#   key_vault_id    = module.key_vault.key_vault_id
#   sql_secret_name = "mssql-credentials"

#   enable_aad_admin        = false
#   azuread_admin_username  = "AzureAD Admin"
#   azuread_admin_object_id = null


#   # Network Mode (UAT/PROD toggle)
#   enable_public_access    = true # PROD → false (private only), UAT → can be true if needed
#   enable_private_endpoint = true
#   private_subnet_id       = module.virtual_network.subnet_lookup["private_endpoint"]
#   private_dns_zone_id     = module.private_dns.zone_ids["privatelink.database.windows.net"]

#   # Service Endpoint
#   enable_service_endpoint_mssql = false
#   app_subnet_id                 = module.virtual_network.subnet_lookup["db"]

#   allowed_ips = ["49.37.211.93"] # only used if public enabled

#   # TDE (Encryption) /* false = system managed key */
#   enable_tde       = false
#   use_cmk_tde      = false
#   key_vault_key_id = null
#   # key_vault_key_id = module.key_vault.sql_tde_key_id


#   # Auditing
#   enable_auditing        = false
#   audit_storage_endpoint = module.mssql_storage_account.primary_blob_endpoint
#   audit_retention_days   = 1


#   # Security Alerts
#   enable_security_alerts = false
#   alert_retention_days   = 1
#   alerts_state           = "Enabled"

#   # Email Accounts
#   email_account_admins = false
#   email_addresses = [
#     "dba@company.com",
#     "cloudops@company.com",
#     "security@company.com"
#   ]

#   # Vulnerability Assessment
#   enable_va = false
#   va_state  = false # or "Disabled"

#   va_storage_container = module.mssql_storage_account.container_urls["sql-va-logs"]
#   va_storage_key       = module.mssql_storage_account.primary_access_key


#   # Backup / LTR
#   short_term_retention_days = 7

#   enable_long_term_retention = false

#   ltr_weekly_retention  = "P4W"
#   ltr_monthly_retention = "P12M"
#   ltr_yearly_retention  = "P3Y"
#   ltr_week_of_year      = 1


#   # Optional Features
#   enable_outbound_firewall = false

#   # Dependencies
#   depends_on = [
#     module.key_vault,
#     module.virtual_network,
#     module.mssql_storage_account,
#     module.private_dns
#   ]
# }

module "acr" {
  source = "../../modules/az-acr"

  # Basic Identity
  env      = local.env
  workload = local.workload

  acr_name            = "${local.env}${local.workload}acr01"
  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # SKU (Critical Control)
  /* Allowed: Basic | Standard | Premium (case-sensitive) */
  sku = "Standard"

  # Access Control
  admin_enabled = false



  # WARNING:
  /* Public access enabled for UAT/debugging.
  Set false in PROD when using Private Endpoint only. */
  public_network_access_enabled = true

  allowed_ips = []

  identity_type = "SystemAssigned"

  # Networking Features
  /* Note:
     These features are PREMIUM-only in real Azure behavior; Keep "true" only if premimum SKU is used.
     Validation in module should block invalid SKU usage. */
  #---
  /* If enabled (true), identity must be "UserAssigned" for Key Vault CMK integration */
  enable_cmk = false

  /* Key Vault Key ID used for CMK encryption (Premium only).
  Set only when enable_cmk = true, otherwise keep null */
  acr_cmk_id = null

  /* enable below id only in Premium CMK setup: */
  # acr_cmk_id = module.key_vault.acr_cmk_id 


  enable_data_endpoint  = false
  enable_georeplication = false

  enable_private_endpoint = false
  private_subnet_id       = module.virtual_network.subnet_lookup["private_endpoint"]
  private_dns_zone_id     = module.private_dns.zone_ids["privatelink.azurecr.io"]

  zone_redundancy_enabled = false
  #---
  /* Image Lifecycle: Cleanup of untagged images only */
  enable_retention_policy = false
  retention_days          = 7

  # Security Policies
  export_policy_enabled  = true /* Controls whether ACR images can be exported to external storage (e.g., Azure Blob for backup/archival) */
  anonymous_pull_enabled = false /* Allows unauthenticated (public) pull access to container images when enabled */

  # Identity-based access (future)
  enable_token       = true /* Enables ACR token-based authentication for fine-grained access control using scope maps */
  key_vault_id_token = module.key_vault.key_vault_id

  # Slack / Teams / CI pipeline hook
  enable_webhook = false /* Enables ACR webhook notifications for events like image push/pull (e.g., Slack/CI/CD integration) */
  webhook_uri    = "https://hooks.slack.com/services/XXXX" /*  Endpoint URL where ACR sends event notifications when webhook is enabled */

  depends_on = [
    module.virtual_network,
    module.private_dns
  ]
}

module "action_group" {
  source = "../../modules/az-action_group"

  name                = "${local.env}-common-alerts"
  short_name          = "alerts"
  resource_group_name = module.rg.resource_group_name

  emails = [
    "chandranchrist@gmail.com"
  ]
}

module "log_analytics" {
  source = "../../modules/az-log-analytics"

  # Basic Identity
  env      = local.env
  workload = local.workload

  name                = "${local.env}-${local.workload}-law-main" # -> UAT; Workspace for per environment.
  location            = module.rg.resource_group_location
  resource_group_name = module.rg.resource_group_name
  tags                = module.rg.tags

  # IAM control
  create_monitoring_group = true
  monitoring_group_name   = "app-monitoring-readers"
  add_current_user        = true

  sku               = "PerGB2018"
  retention_in_days = 30
  daily_quota_gb    = 1

  # Explicit configs (so you KNOW what’s enabled)
  allow_resource_only_permissions         = true
  local_authentication_enabled            = true
  internet_query_enabled                  = true
  immediate_data_purge_on_30_days_enabled = false
}

# module "aks" {
#   source = "../../modules/az-compute/aks"


#   env      = local.env
#   workload = local.workload

#   name                = "${local.env}${local.workload}aks"
#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   kubernetes_version = "1.35"

#   sku_tier = "Standard"

#   dns_prefix                 = "${local.env}aks"
#   dns_prefix_private_cluster = "${local.env}aks-private"

#   private_cluster_enabled             = true
#   private_cluster_public_fqdn_enabled = false
#   private_dns_zone_id                 = null

#   automatic_upgrade_channel = null /* patch/rapid/node-image/stable  */
#   node_os_upgrade_channel   = "None" /* Unmanaged/SecurityPatch/NodeImage/None */

#   api_server_access_profile = {
#     authorized_ip_ranges = [/* Set of authorized IP ranges to allow access to API server */
#       "10.0.1.0/27",
#       "49.37.211.93"
#     ]
#   }

#   auto_scaler_profile = {
#     /* When multiple node pools are similar (same size/labels), AKS cluster autoscaler tries to distribute scale-out across them instead of scaling only one pool. */
#     balance_similar_node_groups = false
#   }

#   aad_rbac = {
#     enabled            = true
#     azure_rbac_enabled = true
#   }

#   role_based_access_control_enabled = true

#   disk_encryption_set_id = null

#   http_application_routing_enabled = false

#   identity = {
#     /* AKS cluster managed identity (control plane identity);
#     Used for Azure resource operations (LB, networking, node pools);
#     Azure creates and manages this automatically */
#     type = "SystemAssigned"
#   }

#   /* Node (kubelet) managed identity
#   # Used by AKS nodes to access Azure resources
#   # Examples: pull images from ACR, mount disks/files
#   # Empty {} = Azure auto-creates and manages it */
#   kubelet_identity = {}

#   /* Forces authentication via Azure AD (Entra ID) instead of static credentials */
#   local_account_disabled = true

#   enable_ssh      = true
#   admin_username  = "HBAdmin"
#   ssh_secret_name = "linux-ssh-public-key"
#   key_vault_id    = module.key_vault.key_vault_id

#   enable_maintenance_window = true

#   acr_id = module.acr.acr_id

#   enable_defender = false

#   defender_workspace_id = null
#   # defender_workspace_id = module.log_analytics.workspace_id
#   # defender_workspace_id = "/subscriptions/xxx/resourceGroups/rg/providers/Microsoft.OperationalInsights/workspaces/ws"

#   monitor_metrics = false

#   network_profile = {
#     network_plugin = "azure"
#     network_policy = "calico"
#   }

#   /* Enables AKS to publish an OIDC identity endpoint for secure token-based authentication */
#   oidc_issuer_enabled = true

#   /* Allows pods to use Azure AD Workload Identity to access Azure resources without secrets */
#   workload_identity_enabled = true

#   /* Enables Azure Monitor (OMS agent) to collect AKS logs and send them to Log Analytics Workspace */
#   enable_oms_agent = true
#   # log_analytics_workspace_id = null
#   log_analytics_workspace_id = module.log_analytics.workspace_id

#   storage_profile = {
#     blob_driver_enabled = true
#   }

#   support_plan = "KubernetesOfficial"

#   run_command_enabled = false

#   # NODE POOL (optional inline structure)
#   default_node_pool = {
#     name                 = "system"
#     node_count           = 1
#     vm_size              = "Standard_B2s"
#     auto_scaling_enabled = true
#     min_count            = 1
#     max_count            = 3
#     vnet_subnet_id       = module.virtual_network.subnet_lookup["aks"]
#   }

#   # NODE POOLS (extra)
#   node_pools = {
#     workernode = {
#       name                 = "workernode1"
#       vm_size              = "Standard_B2s"
#       node_count           = 1
#       auto_scaling_enabled = true
#       min_count            = 1
#       max_count            = 3
#       vnet_subnet_id       = module.virtual_network.subnet_lookup["aks"]
#     }
#   }

#   # EXTENSIONS
#   extensions = {
#     container-storage = {
#       type = "AzureContainerStorage"
#     }

#     backup = {
#       type = "AzureBackup"
#     }

#     network-insights = {
#       type = "ContainerNetworkObservability"
#     }

#     app-config = {
#       type = "AzureAppConfigurationKubernetesProvider"
#     }
#   }



#   # DEPLOYMENT SAFEGUARD
#   deployment_safeguard = {
#     level = "Warn" /* "Warn"/"Enforce" */
#   }

#   # TRUSTED ACCESS
#   enable_trusted_access = false
#   trusted_access = {
#     backup_service = {
#       name               = "backup"
#       source_resource_id = "/subscriptions/xxx/providers/Microsoft.DataProtection/backupVaults/vault1"
#       roles              = ["Microsoft.DataProtection/backupVaults/backup/read"]
#     }
#   }

#   depends_on = [
#     module.rg,
#     module.virtual_network,
#     module.key_vault,
#     module.acr,
#     module.private_dns,
#     module.log_analytics,
#   ]
# }

# module "monitoring" {
#   source = "../../modules/az-compute/aks/monitoring"

#   aks_dcr_name        = "dcr-aks-balanced"
#   aks_dcr_association = "aks-dcr-association"

#   location                   = module.rg.resource_group_location
#   resource_group_name        = module.rg.resource_group_name
#   log_analytics_workspace_id = module.log_analytics.workspace_id
#   aks_id                     = module.aks.aks_id

#   action_group_id = module.action_group.id

#   depends_on = [
#     module.aks,
#     module.action_group,
#     module.log_analytics
#   ]
# }

# Linux App Service Plan
# module "appservice_plan_linux" {
#   source = "../../modules/az-appserviceplan"


#   env      = local.env
#   workload = local.workload

#   name                = "${local.env}-${local.workload}-lnx-srvplan"
#   resource_group_name = module.rg.resource_group_name
#   location            = module.rg.resource_group_location
#   tags                = module.rg.tags

#   os_type  = "Linux"
#   sku_name = "S1"

#   zone_balancing_enabled = false
# }

# module "app_service" {
#   source = "../../modules/az-appservice_webapp"

#   # Basic Identity
#   env      = local.env
#   workload = local.workload

#   name                = "${local.env}-${local.workload}-fe-lnx-webapp"
#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name
#   tags                = module.rg.tags

#   app_service_plan_id = module.appservice_plan_linux.app_service_plan_id

#   https_only                    = true
#   public_network_access_enabled = true
#   identity_type                 = "SystemAssigned"

#   subnet_id           = module.virtual_network.subnet_lookup["app"]
#   key_vault_secret_id = module.key_vault.certificate_secret_ids["wildcard-cert"]

#   domain        = "hbcdev.co.in"
#   prod_hostname = "bookshop"
#   uat_hostname  = "uat-bookshop"

#   key_vault_id        = module.key_vault.key_vault_id
#   godaddy_secret_name = "godaddy-apikey"

#   storage_account_id = module.storage_account["sa1"].storage_account_id

#   app_logs_sas_url  = module.storage_account["sa1"].container_urls["app-logs"]
#   http_logs_sas_url = module.storage_account["sa1"].container_urls["http-logs"]

#   enable_app_insights = true
#   # app_insights_key    = null
#   app_insights_key = module.app_insights.connection_string

#   ip_restrictions = [
#     {
#       name       = "office-ip"
#       ip_address = "49.37.211.93/32"
#       priority   = 100
#       action     = "Allow"
#     }
#     # {
#     #   name       = "vpn"
#     #   ip_address = "103.XX.XX.0/24"
#     #   priority   = 110
#     #   action     = "Allow"
#     # }
#   ]

#   # -----------------------------
#   # BACKUP VALUES (HERE ONLY)
#   # -----------------------------
#   backup_config = {
#     enabled                  = true
#     storage_account_url      = module.storage_account["sa1"].container_urls["backups"]
#     frequency_interval       = 1
#     frequency_unit           = "Day"
#     retention_period_days    = 7
#     keep_at_least_one_backup = true
#     start_time               = "2026-04-25T02:00:00Z"
#   }

#   depends_on = [
#     module.key_vault,
#     module.virtual_network,
#     module.storage_account,
#     module.private_dns,
#     module.appservice_plan_linux
#   ]
# }

# module "app_insights" {
#   source = "../../modules/az-appservice_webapp/app_insights"

#   name                = "${local.env}${local.workload}-appi"
#   location            = module.rg.resource_group_location
#   resource_group_name = module.rg.resource_group_name

#   workspace_id        = module.log_analytics.workspace_id
#   sampling_percentage = 100 # or override later
#   retention_in_days   = 30

#   action_group_id = module.action_group.id
# }

