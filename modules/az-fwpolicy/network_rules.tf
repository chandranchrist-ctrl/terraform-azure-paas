/* Network Security - Network Rules (IP/Port based filtering);
Controls traffic using IPs, ports, and protocols (L3/L4) */
locals {
  network_rule_collections = [
    {
      name     = "network-deny"
      priority = 100
      action   = "Deny"
      rules = [
        {
          name                  = "Block-Google-DNS"
          enabled               = false /* Only creates rules if enabled = true */
          source_addresses      = var.all_vm_cidrs
          destination_addresses = ["8.8.8.8"]
          destination_ports     = ["53"]
          protocols             = ["TCP", "UDP"]
        }
      ]
    },
    {
      name     = "network-allow"
      priority = 200
      action   = "Allow"
      rules = [
        {
          name                  = "Allow-DNS"
          enabled               = true
          source_addresses      = var.all_vm_cidrs
          destination_addresses = ["*"]
          destination_ports     = ["53"]
          protocols             = ["TCP", "UDP"]
        },
        {
          name                  = "Allow-Internet"
          enabled               = false
          source_addresses      = var.all_vm_cidrs
          destination_addresses = ["0.0.0.0/0"]
          destination_ports     = ["80", "443"]
          protocols             = ["TCP"]
        }
      ]
    }
  ]
}