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

## 🏗️ Core Resource Layout

The infrastructure is organized using a modular Terraform architecture where each Azure service is deployed through dedicated reusable modules. Environment-specific deployments consume these modules through separate environment folders.

The deployment structure separates:
*   Core networking resources
*   Identity and RBAC configuration
*   Compute services
*   Monitoring services
*   Security integrations
*   DNS and certificate management

This separation allows controlled deployments, easier maintenance, and environment scalability.

## 🌐 Network Segmentation

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

## 🔒 Environment Isolation

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

---

## 1.2 Traffic Flow Architecture

## 🚦 Frontend Traffic Flow

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

## 🔄 Backend Communication Flow

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

## 📦 AKS ↔ ACR Communication

AKS integrates with Azure Container Registry using kubelet-managed identity authentication.

The architecture avoids credential-based image pulls and instead uses:

*   Managed identities
*   RBAC-based ACR access
*   AcrPull role assignments

📌 This allows cluster nodes to securely pull container images without exposing credentials inside workloads.

## 🔗 App Service ↔ Backend API Communication

The App Service module supports backend API communication using configurable application settings.

Backend endpoints are injected into the application configuration through Terraform-managed app settings, enabling:

*   Environment-specific API routing
*   Internal communication patterns
*   Secure backend connectivity
    
📌 When VNet integration is enabled, the application can access private backend resources directly within the virtual network.

## 🌐 DNS Resolution Behavior

Private DNS zones are integrated to support internal Azure service resolution.

The architecture supports:

*   AKS private DNS resolution
*   App Service private endpoint resolution
*   Private service communication
*   Internal hostname resolution

📌 Both system-managed and custom private DNS approaches are supported for AKS deployments.

## 🔐 Public / Private Routing Model

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

---

## 1.3 Platform Modules & Implementation Highlights

## 🌐 Private DNS Module

The DNS module centralizes private name resolution for Azure-managed services.

The implementation supports:

*   AKS private cluster DNS zones
*   App Service private endpoint zones
*   VNet-linked private resolution
*   Environment-based DNS management
    
📌 The design allows services to communicate privately without exposing internal endpoints publicly.

## 🔐 Access / RBAC Module

* The RBAC module centralizes Azure AD group integration and role assignment management using Azure RBAC, managed identities, and service-specific role mappings.
* Role assignments are dynamically associated with resources such as AKS, ACR, Key Vault, App Service, and networking components to support identity-driven access governance. 

📌 This approach improves access management consistency while avoiding hardcoded identity dependencies across the platform.

## 📦 ACR Module

The Azure Container Registry module supports secure image storage and controlled image pull access.

The module includes:

*   RBAC-based image access
*   Private networking support
*   Managed identity integration
*   Optional retention configuration
*   Registry isolation patterns
    
📌 The implementation also accounts for the separation between management plane RBAC and data plane RBAC, which became an important operational consideration and learning during deployment and access validation workflows.

## ☸️ AKS Module

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

## ⚙️ App Service Plan Module

The App Service Plan module provides reusable Linux hosting plan deployment with configurable SKUs and scaling behavior.

The implementation supports:

*   Linux-based hosting
*   Configurable SKUs
*   Zone balancing support
*   Shared reusable compute layer for App Services

## 🌍 App Service Web App Module

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

## 🔑 Managed Identities

* The platform extensively uses Azure Managed Identities to enable secure, identity-based authentication without relying on hardcoded credentials or secrets. 
* Managed identities are leveraged for AKS kubelet authentication, App Service access to Key Vault, ACR image pull operations, monitoring integrations, and internal Azure service communication. 

📌 This approach improves security by reducing credential exposure while simplifying authentication and secret management across the platform.

## 🛡️ RBAC Strategy

* Azure RBAC is implemented using centralized Azure AD group assignments and Terraform-managed role mappings to provide controlled, identity-driven access management across the platform. 
* The RBAC model follows least-privilege principles with environment-based access separation, service-specific role assignments, and dynamic role attachment patterns.

📌 Roles are assigned across resources such as AKS, ACR, Key Vault, Resource Groups, monitoring services, and networking components to ensure consistent and scalable access governance.

## 🔐 Key Vault Integration

* Azure Key Vault is integrated to provide centralized secret and certificate management across the platform.
* The implementation supports managed identity-based secret access, SSL certificate storage, application secret retrieval, and centralized management of sensitive configurations.

📌 Applications securely retrieve secrets directly from Key Vault without embedding credentials or sensitive values within Terraform configurations or application code.

## 🚫 IP Restrictions

* Network access restrictions are implemented using App Service access restrictions, SCM endpoint restrictions, NSG-based subnet filtering, private endpoint isolation, and controlled ingress patterns.

📌 These controls help minimize unnecessary public exposure and strengthen network-level security across platform services.

## 🔒 TLS Enforcement

HTTPS-only communication is enforced across application endpoints.

The implementation includes:

*   TLS-enabled App Services
*   SSL certificate bindings
*   HTTPS redirection
*   Secure custom domain integration
    
## 🔗 Private Endpoints

* Private Endpoints are used to enable secure internal communication between Azure services over the private network.
* The implementation supports private connectivity for App Service, Key Vault, and Azure SQL Database (MSSQL), helping reduce public exposure of critical platform components.

📌 Private DNS integration is configured to ensure proper internal hostname resolution for privately exposed services.

## ⚠️ Deployment Safeguards (AKS)

* The AKS deployment architecture includes operational safeguards implemented through Terraform using conditional resource protection, controlled feature toggles, environment-aware deployment logic, and preventive validation structures.

📌 These safeguards help minimize accidental infrastructure misconfigurations and improve deployment consistency across environments.

---

# 3. Monitoring & Observability

## 📊 Log Analytics

* Centralized logging is implemented using Azure Log Analytics workspaces to provide unified monitoring and operational visibility across the platform.
* The implementation aggregates AKS logs, App Service application logs, diagnostic logs from services such as Key Vault and jump host VMs, and AKS platform metrics into a centralized workspace.

📌 This enables streamlined monitoring, troubleshooting, and cross-environment operational visibility.

## 📈 Application Insights (App Service)

* Application Insights is integrated to provide application-level observability and telemetry collection across the platform.
* The implementation supports application performance monitoring and request tracing to help analyze application behavior, performance trends, and runtime issues.

📌 Application Insights configuration is dynamically injected through Terraform-managed application settings for consistent environment-based deployment configuration.

## ☸️ AKS DCR Monitoring

* AKS monitoring is implemented using a Data Collection Rules (DCR)-based monitoring architecture integrated with Azure Monitor and Log Analytics.
* The implementation supports container insights, cluster performance monitoring, node telemetry, pod-level diagnostics, and centralized log collection.

📌 Selective monitoring configurations and exclusions were also considered to optimize log collection behavior and reduce unnecessary telemetry overhead within lab-constrained environments.

## 🗄️ Blob Log Storage

Diagnostic and application logs can also be exported to Azure Storage Accounts for long-term retention and operational troubleshooting.

Blob-based logging supports:

*   Persistent log archival
*   Backup diagnostics
*   Historical troubleshooting
*   Cost-optimized log retention

---

# 4. Deployment Workflow

- `terraform init`  
  Initializes the Terraform working directory and downloads required providers.

- `terraform plan`  
  Validates and previews infrastructure changes before deployment.

- `terraform apply`  
  Deploys approved infrastructure changes to Azure.

## ✅ Validation Flow

Post-deployment validation includes:

*   Resource provisioning verification
*   DNS resolution checks
*   Application accessibility validation
*   Managed identity verification
*   Private endpoint connectivity checks
*   Monitoring integration validation
*   RBAC assignment verification

📌 Validation is performed using both Azure CLI and application-level testing workflows.

---

# 5. Operational Challenges & Lessons Learned

📌 This project introduced several real-world operational behaviors and Azure platform considerations that influenced the final implementation design.

## ⏳ RBAC Propagation Timing

* An important operational behavior observed in the platform was that Azure RBAC role assignments may require propagation time before permissions become fully effective across services.
*  This affected AKS ↔ ACR integrations, managed identity authentication, Key Vault access validation, and Terraform deployment sequencing.

📌 To handle these timing dependencies, deployment workflows incorporated validation retries, controlled dependency ordering, and temporary wait periods to ensure RBAC permissions were properly propagated before dependent resources attempted access operations.

## 🔐 ACR RBAC Separation

* During implementation, an important operational learning was understanding the separation between Azure Container Registry management plane RBAC and data plane RBAC permissions.
* There were scenarios where administrative-level access to the registry existed successfully, but AKS image pull operations still failed because the required AcrPull role assignment was not configured for the kubelet managed identity.

📌 This highlighted the importance of correctly configuring both management and image pull permissions when integrating AKS with ACR using RBAC-based authentication.

## 🌐 VNet Integration Drift

* An operational challenge observed with App Service VNet Integration was intermittent Terraform state drift caused by Azure-managed backend synchronization behavior. In some cases, after running terraform apply, the VNet integration appeared as not configured even though the deployment had completed successfully.

📌 This behavior is important to consider when making changes to App Service configurations, deployment slots, or networking settings, as VNet integration inconsistencies can affect internal communication between the App Service and backend services.

📌 Resolving the issue occasionally required removing the affected resource from Terraform state using `terraform state rm` followed by reapplying the configuration to allow the integration to propagate and attach correctly. This became an important practical learning while handling App Service networking integrations.

## 💾 Backup Restriction Issue

* An operational challenge encountered during App Service backup implementation involved SAS URL formatting and Storage Account network restrictions. The backup configuration required a properly formatted SAS URL, and an issue was identified where the generated Terraform output appended an additional ? character, causing backup operations to fail during configuration validation.

* Another important observation was that App Service backup access to the Storage Account behaves as an application-level authenticated request using the provided SAS URL, rather than a trusted Azure service interaction covered by the AzureServices bypass rule.

📌 Because the Storage Account was configured with default_action = "Deny", backup operations were blocked even with Azure service bypass enabled. To resolve this, App Service outbound IP addresses were dynamically added to the Storage Account network rules to explicitly allow backup access.

📌 This also introduced deployment dependency considerations, since the App Service outbound IPs become available only after the App Service deployment is completed, requiring careful Terraform sequencing and configuration handling.

---

# 6. Useful Operational Commands

- `terraform import`  
  Imports existing Azure resources into Terraform state.

- `terraform state rm`  
  Removes resources from Terraform state without deleting them in Azure.

- `terraform console`  
  Opens an interactive Terraform expression console.

- `az webapp log tail`  
  Streams live App Service application logs.

- `curl`  
  Validates application endpoints and API responses.

📌 Validation loops were frequently used during:

*   DNS propagation testing
*   SSL verification
*   Backend API testing
*   Private endpoint validation

---

# 7. Future Enhancements

* Future platform improvements may include Azure Front Door integration and Web Application Firewall (WAF) capabilities to enhance global routing, edge security, and application protection patterns.

📌 These components were intentionally reserved for future implementation due to lab environment constraints and cost considerations, and were not fully validated as part of the current deployment scope.

---

# 8. Appendix

This section provides supporting reference information related to DNS configuration, Azure RBAC roles, supported service SKUs, and other implementation-specific platform details used throughout the architecture.

## 🌐 DNS Zones

* The implementation uses both public and private DNS zones to support external application access and internal private service communication.
* Public DNS management is integrated through GoDaddy for domain resolution, custom domain bindings, and SSL validation workflows, while Private DNS zones are used for AKS private clusters, App Service private endpoints, MSSQL Private Endpoints, and internal hostname resolution across privately connected Azure services.

## 🛡️ Azure Roles

Common Azure roles used throughout the infrastructure deployment include:

*   Contributor
*   Reader
*   AcrPull
*   Key Vault Secrets User
*   Network Contributor (for aks)
*   Monitoring Reader
    
## ⚙️ Supported SKUs

The implementation uses configurable SKUs across the following Azure services:

*   App Service Plans:         P0v3
*   AKS node pools:            VM Size: Standard_B2s_v2
*   Storage Accounts:          SKU: Standard_LRS
*   Azure Container Registry:  SKU: Premium

📌 SKU selection is environment-driven and optimized for lab-based deployments.

---
# 🚀 Key Design Principles

1. Modular and reusable Terraform-based infrastructure design
2. Security-first architecture with identity-driven access control
3. Environment-isolated deployment structure with configurable integrations
4. Flexible public and private deployment support across platform services
5. Scalable and automation-oriented infrastructure implementation

---

# 📌 Conclusion

This project demonstrates a modular and secure Azure PaaS platform architecture implemented using Terraform with reusable infrastructure modules, enterprise-style deployment patterns, and security-focused integrations.

The implementation covers:

1. AKS and App Service deployments
2. Private networking patterns
3. RBAC-driven access control
4. Managed identity integrations
5. Monitoring and observability
6. Terraform-based automation
7. Environment-based infrastructure deployments

💡 Despite being developed within a constrained lab environment, the architecture follows real-world cloud engineering practices and provides a strong foundation for enterprise-scale Azure platform design.

---

# Important Notes

1. This project is intended for learning, experimentation, and architectural demonstration purposes.
2. Some Azure resources used in this implementation may incur cloud usage costs when deployed.
3. Certain configurations may require subscription-level permissions, elevated RBAC access, or Azure service quotas.
4. Some SKU selections, regional deployments, feature enablement, and scaling configurations were intentionally constrained based on lab environment limitations and cost optimization considerations.
5. While certain deployment choices were optimized for lab constraints, the Terraform codebase remains modular, extensible, and aligned with enterprise implementation patterns.
