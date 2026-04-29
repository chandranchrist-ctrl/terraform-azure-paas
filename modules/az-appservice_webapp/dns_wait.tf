resource "time_sleep" "wait_for_dns" {
  depends_on = [
    null_resource.prod_txt_dns,
    null_resource.prod_cname_dns,
    null_resource.uat_txt_dns,
    null_resource.uat_cname_dns
  ]

  create_duration = "180s"
}

# resource "time_sleep" "wait_for_kv_access" {
#   depends_on = [
#     azurerm_role_assignment.kv_appservice_access
#   ]

#   create_duration = "60s"
# }