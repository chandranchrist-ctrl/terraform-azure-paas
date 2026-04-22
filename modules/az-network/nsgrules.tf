locals {
  # Define NSG rules for each subnet
  # Key format: "<vnet_key>-<subnet_key>" (must match NSG map keys)
  nsg_rules = {
    # Rules for app subnet (example: allow HTTP & HTTPS traffic)
    "spoke-app" = [
      {
        name                    = "allow-http-https"
        priority                = 100
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        source_port_range       = "*"
        destination_port_ranges = ["80", "443"] /* Use "destination_port_ranges" only when specifying multiple ports */

        /* Use "source_address_prefix" for single CIDR/service tag,  */
        /* "source_address_prefixes" for multiple CIDRs/service tags, and  */
        /* "source_application_security_group_ids" for ASG (do not mix them in the same rule) */
        source_address_prefixes = [
          "10.0.2.0/24",
          "10.0.0.0/26"
        ]

        /* Use destination_address_prefix for single CIDR/service tag,  */
        /* destination_address_prefixes for multiple CIDRs/service tags, and  */
        /* destination_application_security_group_ids for ASG (do not mix them in the same rule) */
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      },
      {
        name                    = "allow-http-htttps-from-lb"
        priority                = 102
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        source_port_range       = "*"
        destination_port_ranges = ["80", "443"]

        source_address_prefix      = "AzureLoadBalancer"
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      },
      {
        name                    = "allow-rdp-ssh"
        priority                = 103
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        source_port_range       = "*"
        destination_port_ranges = ["3389", "22"]

        source_address_prefix      = "10.0.4.0/26"
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      },
      {
        name                   = "deny_rule"
        priority               = 1003
        direction              = "Inbound"
        access                 = "Deny"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "*"

        source_address_prefix      = "*"
        destination_address_prefix = "*"

        source_asg = null
        dest_asg   = null
      }
    ]

    # Rules for database subnet (example: allow SQL traffic)
    "spoke-db" = [
      {
        name                   = "allow-sql"
        priority               = 100
        direction              = "Inbound"
        access                 = "Allow"
        protocol               = "Tcp"
        source_port_range      = "*"
        destination_port_range = "1433"
        source_address_prefixes = [
          "10.1.1.64/26"
        ]
        destination_address_prefix = "*"
        source_asg                 = null
        dest_asg                   = null
      }
    ]
  }
}