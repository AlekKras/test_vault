# Use Vault provider
provider "vault" { }

# Create a policy document
data "vault_policy_document" "training" {
    rule {
        path         = "kv-v2/data/training/*"
        capabilities = ["create", "read", "update", "delete", "list"]
    }
    rule {
        path         = "kv-v2/*"
        capabilities = ["list", "read"]
    }
    rule {
        path         = "transit/encrypt/payment"
        capabilities = ["update"]
    }
    rule {
        path         = "transit/decrypt/payment"
        capabilities = ["update"]
    }
    rule {
        path         = "transit/*"
        capabilities = ["read", "list"]
    }
}
