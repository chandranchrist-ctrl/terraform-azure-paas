# Network - Route Table Mapping
locals {
  route_tables_map = { for rt in local.route_definitions : rt.name => rt }
}

# Network - Subnet Associations
locals {
  all_subnet_associations = flatten([
    for rt in local.route_definitions : [
      for sk in rt.subnet_keys : {
        rt_name    = rt.name
        subnet_key = sk
        subnet_id  = lookup(var.subnets_map, sk, null) # picks the correct subnet
      }
    ]
  ])
}

# Network - Flatten Routes
locals {
  all_routes = flatten([
    for rt in local.route_definitions : [
      for r in rt.routes : {
        rt_name = rt.name
        route   = r
      }
    ]
  ])
}


# Network - Route Table Creation
resource "azurerm_route_table" "rt" {
  for_each = var.create_rt ? local.route_tables_map : {}

  name                = "${var.env}-${each.key}-rt"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags
}


# Network - Routes inside Route Tables
/*   next_hop_type:
  VirtualAppliance = route via firewall (uses firewall_ip)
  Internet = direct internet access */

resource "azurerm_route" "dynamic_routes" {
  for_each = var.create_rt ? { for r in local.all_routes : "${r.rt_name}-${r.route.name}" => r } : {}

  name                   = each.value.route.name
  route_table_name       = azurerm_route_table.rt[each.value.rt_name].name
  resource_group_name    = var.resource_group_name
  address_prefix         = each.value.route.address_prefix
  next_hop_type          = each.value.route.next_hop_type
  next_hop_in_ip_address = lookup(each.value.route, "next_hop_ip_address", var.firewall_ip)
}


# Network - Associate Route Table to Subnets
resource "azurerm_subnet_route_table_association" "rt_assoc" {
  for_each = var.create_rt ? { for a in local.all_subnet_associations : "${a.rt_name}-${a.subnet_key}" => a } : {}

  subnet_id      = each.value.subnet_id
  route_table_id = azurerm_route_table.rt[each.value.rt_name].id
}