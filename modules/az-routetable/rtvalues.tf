# Network - Route Definitions
locals {
  route_definitions = [
    {
      name        = "spoke-app"
      subnet_keys = ["app"] /* applies RT to app subnet */
      routes = [
        {
          name                = "internet-via-fw"
          address_prefix      = "0.0.0.0/0" /* all traffic */
          next_hop_type       = "VirtualAppliance"
          next_hop_ip_address = var.firewall_ip /* route via firewall */
        }
        # {
        #   name           = "internet-direct"
        #   address_prefix = "0.0.0.0/0"
        #   next_hop_type  = "Internet"                /*  → direct internet (no firewall) */
        # }
      ]
    }
  ]
}