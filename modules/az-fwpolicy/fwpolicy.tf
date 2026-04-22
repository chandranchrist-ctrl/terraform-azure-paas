# Network Security - Firewall Policy
resource "azurerm_firewall_policy" "fwpolicy" {
  name                = "${var.env}-fwpolicy"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku = var.sku
}

# Network Security - Rule Collection Group
/* contains network, application, and NAT rules */
resource "azurerm_firewall_policy_rule_collection_group" "main" {
  name               = "${var.env}-fw-rcg"
  firewall_policy_id = azurerm_firewall_policy.fwpolicy.id
  priority           = 100

  dynamic "network_rule_collection" {
    for_each = [
      for c in local.network_rule_collections :
      c if length([for r in c.rules : r if r.enabled]) > 0
    ]

    content {
      name     = network_rule_collection.value.name
      priority = network_rule_collection.value.priority
      action   = network_rule_collection.value.action

      dynamic "rule" {
        for_each = [
          for r in network_rule_collection.value.rules : r if r.enabled
        ]

        content {
          name                  = rule.value.name
          source_addresses      = rule.value.source_addresses
          destination_addresses = rule.value.destination_addresses
          destination_ports     = rule.value.destination_ports
          protocols             = rule.value.protocols
        }
      }
    }
  }

  dynamic "application_rule_collection" {
    for_each = [
      for c in local.application_rule_collections :
      c if length([for r in c.rules : r if r.enabled]) > 0
    ]

    content {
      name     = application_rule_collection.value.name
      priority = application_rule_collection.value.priority
      action   = application_rule_collection.value.action

      dynamic "rule" {
        for_each = [
          for r in application_rule_collection.value.rules : r if r.enabled
        ]

        content {
          name             = rule.value.name
          source_addresses = rule.value.source_addresses

          protocols {
            type = "Http"
            port = 80
          }

          protocols {
            type = "Https"
            port = 443
          }

          destination_fqdns = rule.value.destination_fqdns
        }
      }
    }
  }

  dynamic "nat_rule_collection" {
    for_each = [
      for c in local.nat_rule_collections :
      c if length([for r in c.rules : r if r.enabled]) > 0
    ]

    content {
      name     = nat_rule_collection.value.name
      priority = nat_rule_collection.value.priority
      action   = nat_rule_collection.value.action

      dynamic "rule" {
        for_each = [
          for r in nat_rule_collection.value.rules : r if r.enabled
        ]

        content {
          name                = rule.value.name
          source_addresses    = rule.value.source_addresses
          destination_address = rule.value.destination_address
          destination_ports   = rule.value.destination_ports
          translated_address  = length(var.vm_private_ips) > 0 ? var.vm_private_ips[0] : null
          translated_port     = rule.value.translated_port
          protocols           = rule.value.protocols
        }
      }
    }
  }
}