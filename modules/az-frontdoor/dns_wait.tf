/* Introduces a delay to wait for DNS records (TXT/CNAME) to propagate before creating dependent Front Door resources, avoiding validation failures */
resource "time_sleep" "wait_for_fe_dns" {

  for_each = local.enabled ? {
    for k, v in var.apps : k => v if v.enabled
  } : {}

  depends_on = [
    null_resource.frontdoor_txt_dns_record,
    null_resource.frontdoor_cname_dns_record
  ]

  create_duration = "180s"
}