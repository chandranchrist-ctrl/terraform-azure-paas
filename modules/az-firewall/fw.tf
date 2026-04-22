# Public IP for Firewall
resource "azurerm_public_ip" "fwpip" {
  count = var.firewall_mode == "public" ? 1 : 0

  name                = "${var.env}-fwpip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

# Public IP for Management
resource "azurerm_public_ip" "fwmgmtpip" {
  count = var.firewall_mode == "public" ? 1 : 0

  name                = "${var.env}-fwmgmtpip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = var.allocation_method
  sku                 = var.sku
}

# Subnet Mapping
locals {
  subnet_firewall_id   = var.firewall_subnet_id
  subnet_management_id = var.firewall_management_subnet_id
}

# Azure Firewall
resource "azurerm_firewall" "fw" {
  name                = "${var.env}-fw"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  zones               = var.zones

  firewall_policy_id = var.firewall_policy_id /* required for Standard/Premium */

  # Firewall IP Configuration
  ip_configuration {
    name      = "configuration"
    subnet_id = local.subnet_firewall_id

    public_ip_address_id = var.firewall_mode == "public" ? azurerm_public_ip.fwpip[0].id : null
  }

  management_ip_configuration {
    name                 = "management"
    subnet_id            = local.subnet_management_id
    public_ip_address_id = var.firewall_mode == "public" ? azurerm_public_ip.fwmgmtpip[0].id : null
  }
}