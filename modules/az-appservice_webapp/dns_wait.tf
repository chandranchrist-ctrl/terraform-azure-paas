resource "time_sleep" "wait_for_dns" {
  depends_on = [
    null_resource.prod_dns,
    null_resource.uat_dns
  ]

  create_duration = "180s"
}