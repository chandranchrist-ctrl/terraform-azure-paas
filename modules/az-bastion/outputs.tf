output "bastion_id" {
  value = azurerm_bastion_host.bastion.id
}

output "bastion_fqdn" {
  value = azurerm_bastion_host.bastion.dns_name
}

output "public_ip_id" {
  value = azurerm_public_ip.bastion_pip.id
}