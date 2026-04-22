output "policy_id" {
  value       = azurerm_firewall_policy.fwpolicy.id
  description = "Firewall Policy ID"
}

output "policy_name" {
  value       = azurerm_firewall_policy.fwpolicy.name
  description = "Firewall Policy Name"
}