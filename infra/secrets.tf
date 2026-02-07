# ----------------------------------------------------------------------------
# Secrets for Cross-Cloud Access (Azure Credentials)
# ----------------------------------------------------------------------------

# Skipped: Scope "azure-storage-scope" already exists manually
# resource "databricks_secret_scope" "azure_credentials" {
#   name = "azure-storage-scope"
# }

resource "databricks_secret" "azure_client_id" {
  scope        = "azure-storage-scope"
  key          = "azure-client-id"
  string_value = var.azure_client_id
}

resource "databricks_secret" "azure_client_secret" {
  scope        = "azure-storage-scope"
  key          = "azure-client-secret"
  string_value = var.azure_client_secret
}

resource "databricks_secret" "azure_tenant_id" {
  scope        = "azure-storage-scope"
  key          = "azure-tenant-id"
  string_value = var.azure_tenant_id
}
