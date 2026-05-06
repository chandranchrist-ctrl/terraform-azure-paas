/* Adds a delay (only for public setup) to allow DNS records (TXT/CNAME for prod & UAT) to propagate before dependent resources execute, preventing validation issues */
resource "time_sleep" "wait_for_dns" {

  count = local.is_private ? 0 : 1

  depends_on = [
    null_resource.prod_txt_dns,
    null_resource.prod_cname_dns,
    null_resource.uat_txt_dns,
    null_resource.uat_cname_dns
  ]

  create_duration = "180s"
}