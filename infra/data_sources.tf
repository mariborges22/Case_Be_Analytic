# ============================================================================
# Data Sources
# Buscar recursos existentes no Unity Catalog
# ============================================================================

# Catalog Existente
data "databricks_catalog" "existing" {
  name = var.catalog_name
}

# Storage Credential existente
data "databricks_storage_credential" "s3_storage_credential" {
  name = "s3-storage-credential"
}

# Current User (para owner dos recursos)
data "databricks_current_user" "me" {}
