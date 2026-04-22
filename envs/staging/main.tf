terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "uatstatehoteltf16"
    container_name       = "tfstate"
    key                  = "staging.terraform.tfstate"
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.67.0"
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
  workload = "hotel"
}

# Reusable module to create Resource Group
module "rg" {
  source = "../../modules/az-rg"

  env      = local.env
  workload = local.workload

  # Input Variables
  resource_group_name     = "${local.env}-rg"
  resource_group_location = "eastus"

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
  default_outbound_access_enabled = false

  # VNet CIDR
  /* {VNet key = hub\spoke} must match the corresponding key in subnet_address_space to map subnets to the correct VNet */
  vnet_address_space = {
    hub   = ["10.0.0.0/16"]
    spoke = ["10.1.0.0/16"]
  }

  # Subnet CIDR
  /* {Subnet key = AzureFirewallSubnet\app} must align with the VNet key to ensure subnets are created within the correct VNet */
  subnet_address_space = {
    hub = {
      AzureFirewallSubnet = {
        cidr = ["10.0.0.0/26"]
        tags = { type = "infra" }
      }

      AppGatewaySubnet = {
        cidr = ["10.0.2.0/24"]
        tags = { type = "infra" }
      }

      AzureFirewallManagementSubnet = {
        cidr = ["10.0.3.0/26"]
        tags = { type = "infra" }
      }

      AzureBastionSubnet = {
        cidr = ["10.0.4.0/26"]
        tags = { type = "infra" }
      }
    }

    spoke = {
      app = {
        cidr = ["10.1.1.64/26"]
        tags = { type = "workload" }
      }

      db = {
        cidr = ["10.1.1.128/26"]
        tags = { type = "workload" }
      }
    }
  }
}


# Network - VNet Peering
module "vnet_peering" {
  source = "../../modules/az-vnet-peering"


  peerings = {
    hub_to_spoke = {
      name                    = "${local.env}-hub-to-spoke"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["hub"].name
      remote_vnet_id          = module.virtual_network.vnets["spoke"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    },
    spoke_to_hub = {
      name                    = "${local.env}-spoke-to-hub"
      resource_group          = module.rg.resource_group_name
      vnet_name               = module.virtual_network.vnets["spoke"].name
      remote_vnet_id          = module.virtual_network.vnets["hub"].id
      allow_vnet_access       = true
      allow_forwarded_traffic = true
      allow_gateway_transit   = false
      use_remote_gateways     = false
    }
  }

  /* {depends_on} ensures VNet creation is completed before establishing peering */
  depends_on = [module.virtual_network]
}

# Storage - Storage Account{for diagnostics}
module "storage_account" {
  source = "../../modules/az-storage"

  # storage_account_name = var.storage_account_name       # "${local.env}storageaccdiag16" /* Storage Account names must be globally unique across Azure. */
  for_each             = var.storage_accounts
  storage_account_name = each.value

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

  allowed_ip_rules = ["49.37.211.249"] /* allows access from specific public IPs */

  # Lifecycle Enabled
  /* lifecycle_rules = [] - lifecycle NOT needed → empty or omitted */
  lifecycle_rules = [
    {
      name   = "diag-cleanup"
      prefix = ["bootdiagnostics", "insights-logs"]
      days   = 1
    }
  ]
}

# Storage - Storage Account{for mssql VA & Audit}
module "sql_logs_storage_account" {
  source = "../../modules/az-storage"

  storage_account_name = var.sql_logs_storage_account_name

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

  allowed_ip_rules = ["49.37.211.249"]

  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["app"],
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
      days   = 7
    },
    {
      name   = "va-retention"
      prefix = ["sql-va-logs"]
      days   = 7
    }
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
  rbac_authorization_enabled = false

  /* true = creates access for current user, false = no access policy */
  create_access_policy_me = true

  /* standard = basic features, premium = supports HSM-backed keys */
  sku_name = "standard" # Standard or Premium

  soft_delete_retention_days = 7 /* days to retain deleted items (7–90) */
  purge_protection_enabled   = false /* true = prevents permanent deletion, false = allows purge */

  enabled_for_deployment          = true /* true = allows VM deployment access */
  enabled_for_template_deployment = true /* true = allows ARM template access */


  public_network_access_enabled = true /* true = allows public access, false = private only */

  network_acls_default_action = "Deny" /* Deny = block all except allowed, Allow = open access */
  allowed_ip_ranges           = ["49.37.211.249/32"] /* allowed public IPs */

  /*   For subnet restrictions, ensure the subnets exist and are correctly referenced.
  service_endpoints = ["Microsoft.KeyVault"] is enabled on those subnets in the network module. */
  allowed_subnet_ids = [
    module.virtual_network.subnet_lookup["app"],
    module.virtual_network.subnet_lookup["db"],
    module.virtual_network.subnet_lookup["AppGatewaySubnet"]
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
  audit_storage_account_name = module.storage_account["sa1"].storage_account_name /* Ex. "kvlogstorage" to declare the name directly */
  audit_storage_account_rg   = module.rg.resource_group_name

  # depends_on ensures storage account is created before enabling diagnostics
  depends_on = [module.storage_account]
}

# Network - Private DNS
module "private_dns" {
  source = "../../modules/az-dns/private"

  resource_group_name = module.rg.resource_group_name

  /* list of private DNS zones to create */
  zones = [
    "privatelink.database.windows.net",
    "privatelink.blob.core.windows.net",
    "privatelink.vaultcore.azure.net"
  ]

  /* VNets to link with DNS zones for name resolution */
  vnet_ids = [
    module.virtual_network.vnets["hub"].id,
    module.virtual_network.vnets["spoke"].id
  ]

  /* Alternative Declaration {vnet_ids}: dynamically fetch all VNet IDs from module output;
Use when you want to link DNS to all VNets automatically (no manual selection needed);
Not needed if only specific VNets (e.g., hub/spoke) should be linked */

  /*   vnet_ids = [
    for v in module.virtual_network.vnets : v.id
  ] */
}

# Network - Route Tables
module "route_tables" {
  source = "../../modules/az-routetable"

  /* true = creates route tables, false = skips creation */
  create_rt = true

  env = "${local.env}-rt"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  subnets_map = module.virtual_network.subnet_lookup /* maps subnet name → subnet ID */

  # optional: pass it if submodule declares it
  # firewall_ip = "10.1.0.4"
  firewall_ip = module.firewall.private_ip /* used as next hop for traffic (Firewall) */
  # firewall_ip = module.firewall_basic.private_ip
}


/* Below code is for creating Azure Firewall (required for Standard/Premium SKU) */
module "firewall" {
  source = "../../modules/az-firewall"

  env = local.env

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # FW PIP & MGMT PIP Configuration
  allocation_method = "Static" /* Static = fixed IP, Dynamic = changes */
  sku               = "Standard" /* required for Azure Firewall */

  #FW Configuration
  sku_name = "AZFW_VNet" /* sku_name: AZFW_VNet = Firewall deployed inside a VNet (most common); AZFW_Hub  = Firewall deployed in Virtual Hub (used with Azure Virtual WAN) */
  sku_tier = "Basic" /* Basic = limited, Standard/Premium = advanced features */
  zones    = [] /* Optional: for zone redundancy; zones = ["1", "2", "3"] */

  firewall_mode = "public" /* public = uses public IP, private = no public IP */

  firewall_policy_id = module.fw_policy.policy_id /* Required for Standard/Premium */

  # Subnets (mandatory Azure naming)
  firewall_subnet_id            = module.virtual_network.subnet_lookup["AzureFirewallSubnet"]
  firewall_management_subnet_id = module.virtual_network.subnet_lookup["AzureFirewallManagementSubnet"]
}

# Network Security - Firewall Policy
module "fw_policy" {
  source = "../../modules/az-fwpolicy"

  env = local.env

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  sku = "Basic" /* Basic = limited features, Standard/Premium = advanced filtering */

  all_vm_cidrs = concat(["10.1.1.64/26"]) /* source CIDRs for firewall rules */

  firewall_public_ip = module.firewall.firewall_pip /* used in NAT rules */

  /* target VM IPs for DNAT */
  vm_private_ips = flatten([
    # module.linux_vm.private_ip,
    module.windows_vm.private_ip
  ])
}


# Network Security - Azure Bastion
module "bastion" {
  source = "../../modules/az-bastion"

  env = local.env

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  subnet_id = module.virtual_network.subnet_lookup["AzureBastionSubnet"] /* dedicated Bastion subnet */

  sku = "Standard" /* Basic or Standard (Standard = more features) */

  tunneling_enabled  = true /* true = allows native client (SSH/RDP) via Bastion */
  ip_connect_enabled = true /* true = connect using private IP */
  copy_paste_enabled = true /* true = enable clipboard */
  file_copy_enabled  = true /* true = allow file transfer */

  zones = null /* null = no zone redundancy, ["1","2","3"] = zone redundant */

  kerberos_enabled = false /* true = enable Kerberos auth, false = disabled */
}


# Windows VM Deployment Module
/* Creates one or more Windows VMs with networking, disks, identity, and optional integrations (LB, ASG, Backup, Diagnostics) */
module "windows_vm" {
  source = "../../modules/az-compute/windows_vm"

  env      = local.env
  workload = local.workload

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  vm_name  = "${local.env}-${local.workload}-ap"
  vm_count = 1

  vm_size   = "Standard_B2s"
  image_sku = "2019-datacenter-gensecond"

  subnet_id = module.virtual_network.subnet_lookup["app"]

  private_ip_allocation = "Dynamic"

  os_disk_storage_type = "Standard_LRS"
  os_disk_size_gb      = 127

  enable_public_ip = false /* true  → VM gets public IP (direct internet access) */

  enable_availability_set = false /* true  → VMs distributed across fault/update domains (HA within region) */
  availability_set_name   = "biztalk-avset"

  zones = null /* ["1","2","3"] → zone-based high availability; null/empty → no zone (regional deployment) */

  # Controls boot diagnostics storage
  enable_boot_diagnostics               = true
  boot_diagnostics_mode                 = "existing" /* "none", "existing", or "create" */
  boot_diagnostics_storage_account_name = module.storage_account["sa1"].storage_account_name


  /*Fetches admin credentials from Key Vault instead of hardcoding
  Helps secure VM username/password */
  key_vault_id                       = module.key_vault.key_vault_id /* change manually when needed; ensure this KV exists and has the necessary secrets for admin username and password */
  localadmin_credentials_secret_name = "localadmin-credentials"

  enable_asg = false

  # enable_lb = false                       /* true  → attaches VM NICs to Load Balancer backend pool */

  # Scenario 1: Existing LB
  # lb_name              = "existing-lb-name"
  # lb_backend_pool_name = "backend-pool-name"

  # Scenario 2: New LB scenario (created in same Terraform)
  # lb_backend_pool_id = module.loadbalancer.backend_pool_id

  license_type = "Windows_Server" # "Windows_Server", "RHEL", "SLES", "Windows_Client"; adjust based on your image and licensing needs

  data_disks = [
    {
      size_gb      = 127
      lun          = 0
      caching      = "ReadWrite"
      storage_type = "Standard_LRS"
    }
  ]

  # Backup configuration
  enable_backup = false /* true  → enables VM backup using Recovery Services Vault */

  # Recovery Serivce Vault Configuration
  recovery_services_vault_name = "existing-rsv"
  backup_policy_vm             = "existing-policy"

  # Ensure dependencies are created before VM
  depends_on = [
    module.key_vault,
    module.storage_account
  ]
}


# Linux VM Deployment Module
/* Creates one or more Linux VMs with networking, disks, identity, and optional integrations (LB, ASG, Backup, Diagnostics) */
module "linux_vm" {
  source = "../../modules/az-compute/linux_vm"

  env      = local.env
  workload = local.workload

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  vm_name  = "${local.env}-nginx-lnx"
  vm_count = 1

  vm_size   = "Standard_B2s"
  image_sku = "18.04-LTS"

  subnet_id = module.virtual_network.subnet_lookup["app"]

  private_ip_allocation = "Dynamic"

  os_disk_storage_type = "Standard_LRS"
  os_disk_size_gb      = 127

  enable_public_ip = false /* true  → VM gets public IP (direct internet access) */

  enable_availability_set = false /* true  → VMs distributed across fault/update domains (HA within region) */

  availability_set_name = "biztalk-avset"

  zones = null /* ["1","2","3"] → zone-based high availability; null/empty → no zone (regional deployment) */

  enable_boot_diagnostics               = true
  boot_diagnostics_mode                 = "existing" /* "none", "existing", or "create" */
  boot_diagnostics_storage_account_name = module.storage_account["sa1"].storage_account_name

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
    module.storage_account
  ]
}

module "mssql" {
  source = "../../modules/az-compute/rds/mssql"

  # Basic Identity
  server_name   = "${local.env}-${local.workload}-sql1"
  database_name = "${local.env}_${local.workload}_db1"

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Server Config
  server_version = "12.0"

  /* Pricing tier
     Examples:
     Basic → dev/test
     S0/S1 → small workloads
     GP_* → General Purpose (recommended)
     BC_* → Business Critical (high IO + HA) */
  sku_name = "Basic"

  max_size_gb = 2

  # Collation for sorting/comparison
  collation = "SQL_Latin1_General_CP1_CI_AS"

  # Zone redundancy (multi-zone HA)
  zone_redundant = false

  # Read scale (read-only replicas)
  read_scale = false

  # Storage type
  # Local → cheaper
  # Geo → geo-redundant backup
  storage_account_type = "Local"

  storage_account_id = module.sql_logs_storage_account.storage_account_id

  # Authentication (from Key Vault)
  key_vault_id    = module.key_vault.key_vault_id
  sql_secret_name = "mssql-credentials"

  enable_aad_admin        = false
  azuread_admin_username  = "AzureAD Admin"
  azuread_admin_object_id = null


  # Network Mode (UAT/PROD toggle)
  enable_public_access    = true # PROD → false (private only), UAT → can be true if needed
  enable_private_endpoint = true
  private_subnet_id       = module.virtual_network.subnet_lookup["db"]
  private_dns_zone_id     = module.private_dns.zone_ids["privatelink.database.windows.net"]

  # Service Endpoint
  enable_service_endpoint_mssql = true
  app_subnet_id                 = module.virtual_network.subnet_lookup["app"]

  allowed_ips = ["49.37.211.249"] # only used if public enabled

  # TDE (Encryption)
  enable_tde       = false
  use_cmk_tde      = false
  key_vault_key_id = null
  # key_vault_key_id = module.key_vault.sql_tde_key_id


  # Auditing
  enable_auditing        = false
  audit_storage_endpoint = module.sql_logs_storage_account.primary_blob_endpoint
  audit_retention_days   = 1


  # Security Alerts
  enable_security_alerts = false
  alert_retention_days   = 1
  alerts_state           = "Enabled"

  # Email Accounts
  email_account_admins = false
  email_addresses = [
    "dba@company.com",
    "cloudops@company.com",
    "security@company.com"
  ]


  # Vulnerability Assessment
  enable_va = false
  va_state  = false # or "Disabled"

  va_storage_container = module.sql_logs_storage_account.container_urls["sql-va-logs"]
  va_storage_key       = module.sql_logs_storage_account.primary_access_key


  # Backup / LTR
  short_term_retention_days = 7

  enable_long_term_retention = false

  ltr_weekly_retention  = "P4W"
  ltr_monthly_retention = "P12M"
  ltr_yearly_retention  = "P3Y"
  ltr_week_of_year      = 1


  # Optional Features
  enable_outbound_firewall = false

  # Dependencies
  depends_on = [
    module.key_vault,
    module.virtual_network,
    module.sql_logs_storage_account,
    module.private_dns
  ]
}

module "appgw" {
  source = "../../modules/az-applicationgateway"

  env      = local.env
  workload = local.workload

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # appgw Public IP
  allocation_method = "Static"
  sku               = "Standard"

  # SKU configuration for Application Gateway
  sku_name     = "Standard_v2" # The SKU name (Standard_v2, WAF_v2, etc.)
  sku_tier     = "Standard_v2" # The SKU tier (Standard_v2, WAF_v2)
  sku_capacity = 1             # Capacity: Number of instances for the gateway 


  ssl_cert_password = "Y12345Z"

  # key_vault_id = module.key_vault.key_vault_id
  # ssl_cert_secret_id = module.key_vault.certificate_secret_ids["wildcard-cert"]

  # Frontend IP Configuration
  enable_public_ip = true # set to false to create internal-only App Gateway without public IP


  enable_private_ip     = true
  subnet_id             = module.virtual_network.subnet_lookup["AppGatewaySubnet"] # Subnet ID where the Application Gateway will be deployed 
  private_ip_allocation = "Static"                                                 # Private IP allocation type for Application Gateway frontend (Dynamic or Static)
  private_ip_address    = "10.0.2.50"


  # Required variables for routing modules
  frontend_ip_name   = "${local.env}-appgw-fe-ip"
  frontend_port_name = "${local.env}-appgw-fe-port"
  port               = 443 # Port number for incoming traffic (e.g., 80 for HTTP, 443 for HTTPS).
  port_http          = 80  # Port number for incoming traffic (e.g., 80 for HTTP, 443 for HTTPS).

  # Direct Pass (NO locals block required)
  backend_ips = flatten([
    # module.linux_vm.private_ip
    module.windows_vm.private_ip
  ])

  depends_on = [
    module.key_vault
  ]
}


/* Optional  */

/*
module "loadbalancer" {
  source = "../../modules/az-loadbalancer"

  env = local.env
  workload = local.workload

  lb_name = "${local.env}-${local.workload}-lb-pub"           # change to "${local.env}-lb-priv" for private LB

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Public IP
  allocation_method = "Static"
  sku               = "Standard"

  # LB Configuration
  sku_name         = "Standard"           # Standard or Basic
  frontend_ip_type = "Public"             # Public or Private;  For Private LB: use a valid subnet output (e.g., spoke/web); update the key if your subnet naming differs.
  subnet_id        = null                 # Empty means Public LB
  # subnet_id         = module.virtual_network.subnet_lookup["web"] 
}
*/

/*
module "mysql" {
  source = "../../modules/az-compute/rds/mysql-flexible"

  env = local.env
  workload = local.workload

  db_servername = "${local.env}-${local.workload}-db1"
  db_name = "${local.env}_${local.workload}_db1"


  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Server Configuration

  sku_name = "B_Standard_B2s"
  db_version = "8.4"  
  zone = null

  # DB Server to be deployed as public or private 
  enable_private_network = false
  enable_private_dns = false

  vnet_id = module.virtual_network.vnets["spoke"].id
  delegated_subnet_id  = module.virtual_network.subnet_lookup["db"]

  # DB allow NACLs from public inbound
  allowed_ips = ["49.37.211.249"]

  storage_size_gb = 22


  # Enable High Availability (HA)
  enable_ha = false               # false → single instance (no failover); true  → enables standby replica automatically (managed by Azure)
  ha_mode = "ZoneRedundant"       # HA mode (only used when enable_ha = true); ZoneRedundant → primary + standby in different AZs (best for production); SameZone → primary + standby in same AZ (lower cost, less resilient)


  # Key Vault Configuration
  key_vault_id = module.key_vault.key_vault_id
  mysql_credentials_secret_name = "mysql-credentials"


  # Backup Config
  backup_retention_days = 7
  geo_redundant_backup_enabled = false  # Stores backups in: Another Azure region


  # Maintenance Window
  maintenance_day = 5       # Day of week for planned maintenance (Azure patching, updates); maintenance_day = 7   # Sunday
  maintenance_hour = 1    # Hour of day (UTC) when maintenance starts; # Example: # Range: 0–23; 1 = 01:00 UTC

  enable_diagnostics = true
  diagnostic_storage_account_id = module.storage_account["sa1"].storage_account_name

  enable_replica   = false
  replica_location = "Central India"

  # Depends
  depends_on = [module.key_vault]
} 
*/

/* 
module "firewall_basic" {
  source = "../../modules/az-firewall-basicsku"

  env = local.env

  resource_group_name = module.rg.resource_group_name
  location            = module.rg.resource_group_location
  tags                = module.rg.tags

  # Optional: Public IP allocation and zones
  allocation_method = "Static"
  sku               = "Standard"

  #FW Configuration
  sku_name = "AZFW_VNet"            # Firewall deployed in a Virtual Network (not Secure Hub); Basic SKU only supports AZFW_VNet
  sku_tier = "Basic"
  zones    = []
  firewall_mode = "public"
 
  all_vm_cidrs = concat(["10.1.1.0/26"], ["10.1.1.64/26"])

  # Only subnets needed for firewall
  firewall_subnet_id            = module.virtual_network.subnet_lookup["AzureFirewallSubnet"]
  firewall_management_subnet_id = module.virtual_network.subnet_lookup["AzureFirewallManagementSubnet"]
}
 */