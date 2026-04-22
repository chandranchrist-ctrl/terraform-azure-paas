# Network - Route Table Outputs
output "route_tables" {
  value = var.create_rt ? {
    for k, v in azurerm_route_table.rt :
    k => {
      id   = v.id
      name = v.name
    }
  } : {}
}