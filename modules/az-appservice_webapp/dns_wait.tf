resource "time_sleep" "wait_for_dns" {
  depends_on = [
    null_resource.prod_txt_dns,
    null_resource.prod_cname_dns,
    null_resource.uat_txt_dns,
    null_resource.uat_cname_dns
  ]

  create_duration = "180s"
}