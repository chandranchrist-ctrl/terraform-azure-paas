# ------------------------------------------------------------
# Azure Monitor Agent (AMA) installation on Linux VM
# ------------------------------------------------------------
# PURPOSE:
# - Installs monitoring agent inside the VM
# - Required ONLY if you plan to send logs/metrics later
# - Does NOT send data by itself (needs DCR + Log Analytics)
#
# NOTE:
# - Safe to install on running VM (no reboot required)
# - Can be removed anytime without affecting VM
# ------------------------------------------------------------

# Azure Monitor Agent (AMA)
# Installs monitoring agent only (no logs collected yet)

resource "azurerm_virtual_machine_extension" "ama" {
  for_each = toset(local.vm_names)

  name               = "${each.key}-ama"
  virtual_machine_id = azurerm_linux_virtual_machine.vm[each.key].id

  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.0"

  auto_upgrade_minor_version = true

  settings = jsonencode({})
}