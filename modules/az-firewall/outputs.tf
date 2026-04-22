output "firewall_id" {
  value       = azurerm_firewall.fw.id
  description = "The ID of the Azure Firewall"
}

output "firewall_name" {
  value       = azurerm_firewall.fw.name
  description = "The name of the Azure Firewall"
}

output "firewall_pip" {
  value = var.firewall_mode == "public" ? azurerm_public_ip.fwpip[0].ip_address : null
}

output "firewall_pip_id" {
  value = var.firewall_mode == "public" ? azurerm_public_ip.fwpip[0].id : null
}

output "firewall_mgmt_pip" {
  value = var.firewall_mode == "public" ? azurerm_public_ip.fwmgmtpip[0].ip_address : null
}

output "firewall_private_ips" {
  value = {
    firewall_main       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
    firewall_management = azurerm_firewall.fw.management_ip_configuration[0].private_ip_address
  }
}

output "private_ip" {
  value       = azurerm_firewall.fw.ip_configuration[0].private_ip_address
  description = "Private IP of the Firewall (main IP only)"
}