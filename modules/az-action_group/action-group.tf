resource "azurerm_monitor_action_group" "actiongrp" {
  name                = var.name
  resource_group_name = var.resource_group_name
  short_name          = var.short_name

  dynamic "email_receiver" {
    for_each = var.emails

    content {
      name          = replace(email_receiver.value, "@", "-")
      email_address = email_receiver.value
    }
  }
}