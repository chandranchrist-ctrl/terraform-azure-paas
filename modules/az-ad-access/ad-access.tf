# Create Azure AD Groups
resource "azuread_group" "groups" {
  for_each = var.groups

  display_name     = each.value.name
  security_enabled = true
}

# Flatten group-member mapping
locals {
  group_members = flatten([
    for group_key, group in var.groups : [
      for member in group.members : {
        group_key = group_key
        member_id = member
      }
    ]
  ])
}

# Add Members to Groups
resource "azuread_group_member" "members" {
  for_each = {
    for gm in local.group_members :
    "${gm.group_key}-${gm.member_id}" => gm
  }

  group_object_id  = azuread_group.groups[each.value.group_key].object_id
  member_object_id = each.value.member_id
}