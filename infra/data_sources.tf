# ============================================================================
# Data Sources
# Buscar recursos existentes no Unity Catalog
# ============================================================================

# Catalog Existente
data "databricks_catalog" "existing" {
  name = var.catalog_name
}

# Storage Credential existente (testar primeiro nome, se falhar usar o segundo)
data "databricks_storage_credential" "s3_credential" {
  name = "s3-storage-credential"
}

# Current User (para owner dos recursos)
data "databricks_current_user" "me" {}
