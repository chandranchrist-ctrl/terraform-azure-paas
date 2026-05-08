output "bastion_id" {
  value = var.enable_bastion ? azurerm_bastion_host.bastion[0].id : null
}

output "bastion_fqdn" {
  value = azurerm_bastion_host.bastion.dns_name
}

output "public_ip" {
  value = var.enable_bastion ? azurerm_public_ip.bastion_pip[0].ip_address : null
}