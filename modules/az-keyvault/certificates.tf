/* Imports certificates (PFX) into Key Vault;
for_each = creates one certificate per item in var.certificates;
Use when certificates are already generated and need to be stored securely in Key Vault */

# Security - Certificates
resource "azurerm_key_vault_certificate" "cert" {
  for_each = { for c in var.certificates : c.name => c }

  name         = each.value.name
  key_vault_id = azurerm_key_vault.kv.id

  certificate {
    contents = filebase64(each.value.pfx_path)
    password = each.value.password
  }

  depends_on = [
    azurerm_key_vault_access_policy.me
  ]
}

/* Defines how certificates are generated within Key Vault (self-signed or via issuer)
Use when creating certificates directly in Key Vault instead of importing PFX files
Not needed when certificates are already available and imported using pfx_path */

/* certificate_policy {
  issuer_parameters {
    name = "Self"
  }

  key_properties {
    exportable = true
    key_size   = 2048
    key_type   = "RSA"
    reuse_key  = true
  }

  secret_properties {
    content_type = "application/x-pkcs12"
  }

  x509_certificate_properties {
    subject            = "CN=${each.value.name}"
    validity_in_months = 12

    key_usage = [
      "digitalSignature",
      "keyEncipherment"
       ]
     }
   }
} 
*/