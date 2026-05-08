# 🚀 Modular and Secure Azure PaaS Platform Architecture using Terraform

# 📌 Overview

This project implements a reusable Azure infrastructure platform using Terraform with a modular, security-focused, and enterprise-style deployment approach. The platform is designed to support containerized workloads, web applications, private networking, centralized monitoring, RBAC-driven access control, and automated operational integrations.

The implementation combines Azure Kubernetes Service (AKS), App Service, Azure Container Registry (ACR), Key Vault, monitoring services, and network isolation patterns into a reusable Terraform codebase that can be deployed across multiple environments.

## Enterprise-Style Azure Landing Zone Approach

The architecture follows a simplified landing zone-style structure where infrastructure components are separated into reusable modules and deployed through environment-specific configurations.

The design focuses on:

*   Environment isolation
*   Centralized networking
*   Identity-driven access management
*   Modular infrastructure composition
*   Security-first deployment patterns
*   Monitoring and diagnostics integration
*   Public/private deployment flexibility
    

## Reusable Terraform Architecture

The repository is structured around reusable Terraform modules instead of environment-specific hardcoded resources.

Each major Azure service is abstracted into dedicated modules such as:

*   Virtual Network
*   Private DNS
*   AKS
*   App Service
*   ACR
*   Key Vault
*   Monitoring
*   RBAC

The modules are designed using:

*   Dynamic blocks
*   Conditional resource deployment
*   Feature toggles
*   Environment-driven configuration
*   Reusable variable structures

This allows the same infrastructure components to be reused across development, UAT, and production-style deployments with minimal code duplication.

## Lab-Based Implementation Constraints

This implementation was developed as a lab-based architecture project with cost, environment, and operational constraints intentionally considered during the design process.

Some production-grade features were simplified or selectively implemented to balance:

*   Cost optimization
*   Deployment simplicity
*   Learning objectives
*   Infrastructure experimentation
*   Azure service limitations within lab environments
  
Examples include:
*   Single-region deployment
*   Simplified HA strategies
*   Limited node sizing
*   Selective security feature enablement
*   Optional Front Door integration reserved for future expansion
    
Despite these constraints, the platform maintains enterprise-oriented design principles and operational patterns.

## Folder Structure

terraform-azure-infra

- envs                -> Root Module
  - staging
    - main.tf   (Root deployment entry point)

- modules                -> submodule
  - rg
  - virtual_network
  - vnet_peering
  - private_dns
  - key_vault
  - diag_storage_account
  - mssql_storage_account
  - appservice_storage_account
  - log_analytics
  - bastion
  - jumpbox_linux_vm
  - mssql
  - acr
  - aks
  - appservice_plan_linux
  - app_service
  - frontdoor(Optional: Not Tested)

---

# Architecture & Platform Design

## 1. Infrastructure Architecture

### 🏗️ Core Resource Layout

The infrastructure is organized using a modular Terraform architecture where each Azure service is deployed through dedicated reusable modules. Environment-specific deployments consume these modules through separate environment folders.

The deployment structure separates:
*   Core networking resources
*   Identity and RBAC configuration
*   Compute services
*   Monitoring services
*   Security integrations
*   DNS and certificate management

This separation allows controlled deployments, easier maintenance, and environment scalability.

### 🌐 Network Segmentation

The platform uses segmented virtual networking to isolate workloads and infrastructure communication paths.

Dedicated subnets are used for:
*   AKS workloads
*   App Service VNet integration
*   Private Endpoints 

The segmentation strategy improves:

*   Traffic isolation
*   Security enforcement
*   Service delegation handling
*   Controlled private connectivity
    

📌 Subnet delegation and service-specific integrations are implemented where required to support Azure-managed services.

### 🔒 Environment Isolation

The repository separates deployments through environment-specific configurations located under dedicated environment folders.

Each environment controls:

*   Naming conventions
*   Networking ranges
*   Allowed IPs
*   Feature toggles
*   Monitoring behavior
*   DNS behavior
*   Resource sizing

📌 This structure supports repeatable deployments while maintaining logical separation between environments.

## 1.2 Traffic Flow Architecture

### 🚦 Frontend Traffic Flow

Client requests enter through the public application endpoint and are routed toward the frontend application hosted on Azure App Service.

The App Service layer handles:

*   HTTPS termination
*   TLS enforcement
*   Custom domain bindings
*   SSL certificate integration
*   Application logging
*   Optional VNet integration

Traffic restrictions can be applied using:

*   Public access rules
*   SCM IP restrictions
*   Private endpoint-based isolation    

📌 Future architecture expansion includes Azure Front Door integration for global routing and edge-based traffic handling.

### 🔄 Backend Communication Flow

The frontend application communicates with backend services using internal API endpoints configured through application settings.

Backend workloads can be hosted:

*   Inside AKS
*   Behind internal networking
*   Through private communication paths

The architecture supports secure service-to-service communication using:

*   VNet integration
*   Private DNS resolution
*   Managed identities
*   Internal API routing

### 📦 AKS ↔ ACR Communication

AKS integrates with Azure Container Registry using kubelet-managed identity authentication.

The architecture avoids credential-based image pulls and instead uses:

*   Managed identities
*   RBAC-based ACR access
*   AcrPull role assignments

📌 This allows cluster nodes to securely pull container images without exposing credentials inside workloads.

### 🔗 App Service ↔ Backend API Communication

The App Service module supports backend API communication using configurable application settings.

Backend endpoints are injected into the application configuration through Terraform-managed app settings, enabling:

*   Environment-specific API routing
*   Internal communication patterns
*   Secure backend connectivity
    
📌 When VNet integration is enabled, the application can access private backend resources directly within the virtual network.

### 🌐 DNS Resolution Behavior

Private DNS zones are integrated to support internal Azure service resolution.

The architecture supports:

*   AKS private DNS resolution
*   App Service private endpoint resolution
*   Private service communication
*   Internal hostname resolution

📌 Both system-managed and custom private DNS approaches are supported for AKS deployments.

### 🔐 Public / Private Routing Model

The platform supports both public-facing and fully private deployment models through feature toggles.

Public deployments allow:

*   Internet-based application access
*   Public DNS resolution
*   External traffic routing

Private deployments use:

*   Private endpoints
*   Private DNS zones
*   Internal VNet communication
*   Restricted public exposure

📌 This flexibility allows the same Terraform modules to support different security and networking requirements without redesigning infrastructure components.

## 1.3 Platform Modules & Implementation Highlights

### 🌐 Private DNS Module

The DNS module centralizes private name resolution for Azure-managed services.

The implementation supports:

*   AKS private cluster DNS zones
*   App Service private endpoint zones
*   VNet-linked private resolution
*   Environment-based DNS management
    
📌 The design allows services to communicate privately without exposing internal endpoints publicly.

### 🔐 Access / RBAC Module

The RBAC module centralizes Azure AD group integration and role assignment management.

The implementation uses:

*   Azure AD groups
*   Azure RBAC
*   Managed identities
*   Service-specific role mappings
    
Role assignments are dynamically attached to:

*   AKS
*   ACR
*   Key Vault
*   App Service
*   Networking resources
    
📌 This approach simplifies access governance and avoids hardcoded identity dependencies.

### 📦 ACR Module

The Azure Container Registry module supports secure image storage and controlled image pull access.

The module includes:

*   RBAC-based image access
*   Private networking support
*   Managed identity integration
*   Optional retention configuration
*   Registry isolation patterns
    
📌 The implementation also considers separation between:

*   Management plane RBAC
*   Data plane RBAC
    
📌 which became an important operational learning during deployment.

### ☸️ AKS Module

The AKS module is designed with toggle-driven architecture supporting multiple deployment models and operational integrations.

The implementation supports:

*   Public and private AKS deployment modes
*   Optional custom private DNS integration
*   Azure RBAC with Azure AD integration
*   OIDC issuer configuration
*   Workload Identity integration
*   Managed control plane identity
*   Kubelet managed identity
*   Dynamic node pool configuration
*   Optional autoscaling
*   DCR-based monitoring integration  
*   Deployment safeguard support
*   Extension-based cluster enhancements
    
📌 The module uses conditional logic extensively to dynamically enable or disable platform features without modifying the core module structure.

### ⚙️ App Service Plan Module

The App Service Plan module provides reusable Linux hosting plan deployment with configurable SKUs and scaling behavior.

The implementation supports:

*   Linux-based hosting
*   Configurable SKUs
*   Zone balancing support
*   Shared reusable compute layer for App Services

### 🌍 App Service Web App Module

📌 The App Service module is designed around public/private deployment flexibility and operational automation.

The implementation includes:

*   Public and private access modes
*   VNet integration
*   Deployment slot architecture
*   SCM access restrictions
*   Managed identity integration
*   Application Insights integration
*   Storage-backed logging
*   Automated backup integration
*   SSL certificate automation
*   GoDaddy DNS automation
*   Custom domain binding
*   Private endpoint integration
*   Blob-based diagnostic logging
*   Runtime configuration through app settings

The module also automates:

*   DNS validation records
*   CNAME creation
*   SSL certificate binding
*   Managed identity-based Key Vault access
    
# 2. Security & Access Model

### 🔑 Managed Identities


The platform extensively uses Azure Managed Identities to eliminate credential-based authentication wherever possible.

Managed identities are used for:

*   AKS kubelet authentication
*   App Service access to Key Vault
*   ACR image pull operations
*   Monitoring integrations
*   Internal Azure service communication

📌 This reduces credential exposure and simplifies secret management.

### 🛡️ RBAC Strategy

Azure RBAC is implemented using centralized Azure AD group assignments and Terraform-managed role mappings.

The RBAC design includes:

*   Least privilege access principles
*   Environment-based access separation
*   Service-specific role assignments
*   Dynamic RBAC attachment patterns
*   Identity-driven operational access

Roles are assigned across:

*   AKS
*   ACR
*   Key Vault
*   Resource Groups
*   Monitoring resources
*   Networking resources

### 🔐 Key Vault Integration

Azure Key Vault is integrated for centralized secret and certificate management.

The implementation supports:

*   Managed identity-based secret access
*   SSL certificate storage
*   Application secret retrieval
*   Centralized sensitive configuration management
    
📌 Applications retrieve secrets without embedding credentials inside Terraform or application code.

### 🚫 IP Restrictions

Network access restrictions are implemented using:

*   App Service access restrictions
*   SCM endpoint restrictions
*   NSG-based subnet filtering
*   Private endpoint isolation
*   Controlled ingress patterns
    
📌 This helps reduce unnecessary public exposure of platform services.

### 🔒 TLS Enforcement

HTTPS-only communication is enforced across application endpoints.

The implementation includes:

*   TLS-enabled App Services
*   SSL certificate bindings
*   HTTPS redirection
*   Secure custom domain integration
    
### 🔗 Private Endpoints

Private endpoints are used to enable secure internal Azure service communication.

The implementation supports private connectivity for:

*   App Service
*   Key Vault
*   Azure SQLDB (MSSQL) 

📌 Private DNS integration ensures proper internal hostname resolution.

### ⚠️ Deployment Safeguards (AKS)

The Terraform implementation includes operational safeguards such as:

*   Conditional resource protection
*   Controlled feature toggles
*   Environment-aware deployment logic
*   Preventive validation structures
    
📌 These safeguards help reduce accidental infrastructure misconfiguration during deployments.

# 3. Monitoring & Observability

### 📊 Log Analytics

Centralized logging is implemented using Azure Log Analytics workspaces.

The platform aggregates:

*   AKS logs
*   Application logs (appservice)
*   Diagnostic logs (keyvault & jhostvm)
*   Platform metrics (AKS)

📌 This enables centralized operational visibility across environments.

### 📈 Application Insights (App Service)

Application Insights is integrated for application-level observability and telemetry collection.

The implementation supports:

*   Application performance monitoring
*   Request tracing

📌 Application Insights configuration is injected dynamically through Terraform-managed settings.

### ☸️ AKS DCR Monitoring

📌 AKS monitoring is implemented using Data Collection Rules (DCR)-based monitoring architecture.

The implementation supports:

*   Container insights
*   Cluster performance monitoring
*   Node telemetry
*   Pod-level diagnostics
*   Log Analytics integration
    
This aligns with modern Azure Monitor integration patterns.

### 🗄️ Blob Log Storage

Diagnostic and application logs can also be exported to Azure Storage Accounts for long-term retention and operational troubleshooting.

Blob-based logging supports:

*   Persistent log archival
*   Backup diagnostics
*   Historical troubleshooting
*   Cost-optimized log retention

### 🩺 Diagnostics Strategy

The observability architecture follows a layered monitoring approach combining:

*   Platform monitoring
*   Application telemetry
*   Infrastructure diagnostics
*   Log aggregation
*   Centralized operational visibility
    
The monitoring design allows both real-time troubleshooting and historical analysis.

# 4. Deployment Workflow

- `terraform init`  
  Initializes the Terraform working directory and downloads required providers.

- `terraform plan`  
  Validates and previews infrastructure changes before deployment.

- `terraform apply`  
  Deploys approved infrastructure changes to Azure.

### ✅ Validation Flow

Post-deployment validation includes:

*   Resource provisioning verification
*   DNS resolution checks
*   Application accessibility validation
*   Managed identity verification
*   Private endpoint connectivity checks
*   Monitoring integration validation
*   RBAC assignment verification

📌 Validation is performed using both Azure CLI and application-level testing workflows.

# 5. Operational Challenges & Lessons Learned

📌 This project introduced several real-world operational behaviors and Azure platform considerations that influenced the final implementation design.

### ⏳ RBAC Propagation Timing

Azure RBAC assignments may require propagation time before permissions become effective.

This behavior affected:

*   AKS ↔ ACR integration
*   Managed identity access
*   Key Vault access
*   Terraform deployment sequencing
    
📌 Operational delays and retry logic became important during validation.

### 🔐 ACR RBAC Separation

Azure Container Registry separates:

*   Management plane RBAC
*   Data plane RBAC

📌 This created scenarios where administrative access existed while image pull operations still failed due to missing AcrPull assignments.
📌 This became an important operational learning during implementation.

### 🌐 VNet Integration Drift

*  App Service VNet integrations occasionally introduced Terraform drift behavior due to Azure-managed backend changes.
*  Lifecycle ignore rules and validation workflows were evaluated to reduce unnecessary infrastructure churn.

### 💾 Backup Restriction Issue

App Service backup configurations introduced operational limitations when combined with certain storage and networking configurations.

This required careful validation of:

*   Storage account accessibility (If SAS involved)
*   Authentication behavior 

### 🔗 Managed Identity Dependency Ordering

Managed identity-based integrations introduced dependency sequencing challenges during deployment.

Examples included:

*   Key Vault access before application startup
*   AKS image pull authorization
*   Monitoring extension attachment

📌 Terraform dependency management became critical for stable deployments.

# 6. Useful Operational Commands

⚙️ Terraform State & Operations

- `terraform import`  
  Imports existing Azure resources into Terraform state.

- `terraform state rm`  
  Removes resources from Terraform state without deleting them in Azure.

- `terraform console`  
  Opens an interactive Terraform expression console.


📜 Application Log Monitoring

- `az webapp log tail`  
  Streams live App Service application logs.


🌐 Connectivity Validation

- `curl`  
  Validates application endpoints and API responses.

📌 Validation loops were frequently used during:

*   DNS propagation testing
*   SSL verification
*   Backend API testing
*   Private endpoint validation 

# 7. Future Enhancements

Future platform improvements may include:

*   Azure Front Door integration
*   Web Application Firewall (WAF) integration

# 8. Appendix

### 🌐 DNS Zones

The implementation supports both:

*   Public DNS zones
*   Private DNS zones

DNS zones are used for:

*   AKS private clusters
*   App Service private endpoints
*   MSSQL Private Endpoint
*   Internal hostname resolution
*   SSL validation workflows
    
### 🛡️ Azure Roles

Common Azure roles used in the platform include:

*   Contributor
*   Reader
*   AcrPull
*   Key Vault Secrets User
*   Network Contributor (for aks)
*   Monitoring Reader
    
### ⚙️ Supported SKUs

The platform supports configurable SKUs for:

*   App Service Plans
*   AKS node pools
*   Storage Accounts
*   Azure Container Registry

📌 SKU selection is environment-driven and optimized for lab-based deployments.
