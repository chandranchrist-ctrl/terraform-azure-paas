/* Application Rules (FQDN-based filtering - HTTP/HTTPS only);
action = "Allow" is typically used for domain access;
"Deny" is not commonly used here → blocking is usually handled via Network Rules or default deny */

locals {
  application_rule_collections = [
    {
      name     = "allow-business-apps"
      priority = 100
      action   = "Allow"

      rules = [
        {
          name             = "allow-azure-services"
          enabled          = false /* Only creates rules if enabled = true */
          source_addresses = var.all_vm_cidrs
          destination_fqdns = [
            "*.microsoft.com",
            "*.azure.com",
            "*.windows.net"
          ]
        },
        {
          name             = "allow-dev-tools"
          enabled          = false
          source_addresses = var.all_vm_cidrs
          destination_fqdns = [
            "login.github.com",
            "*.visualstudio.com",
            "*.vscode.dev"
          ]
        },
        {
          name             = "allow-package-repos"
          enabled          = false
          source_addresses = var.all_vm_cidrs
          destination_fqdns = [
            "registry.npmjs.org",
            "pypi.org",
            "*.docker.com"
          ]
        }
      ]
    }
  ]
}