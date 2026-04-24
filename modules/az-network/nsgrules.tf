locals {
  # Define NSG rules for each subnet
  # Key format: "<vnet_key>-<subnet_key>" (must match NSG map keys)
  nsg_rules = {
    # Rules for app subnet (example: allow HTTP & HTTPS traffic)
    "be-aks" = [
      {
        name      = "allow-appservice-to-aks"
        priority  = 100
        direction = "Inbound"
        access    = "Allow"
        protocol  = "Tcp"


        source_address_prefixes = [
          "10.1.1.64/26" # appservice CIDR
        ]
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_ranges    = ["80", "443"]
        source_asg                 = null
        dest_asg                   = null
      }
    ]

    # Rules for database subnet (example: allow SQL traffic)
    "be-db" = [
      {
        name      = "allow-sql"
        priority  = 100
        direction = "Inbound"
        access    = "Allow"
        protocol  = "Tcp"
        source_address_prefixes = [
          "172.21.0.0/22" # Aks Nodes CIDR
        ]
        source_port_range          = "*"
        destination_address_prefix = "*"
        destination_port_range     = "1433"
        source_asg                 = null
        dest_asg                   = null
      }
    ]
  }
}