output "catalog_name" {
  value = data.databricks_catalog.existing.name
}

output "schemas" {
  value = {
    bronze = databricks_schema.bronze.id
    silver = databricks_schema.silver.id
    gold   = databricks_schema.gold.id
  }
}

output "external_locations" {
  description = "External locations for S3 data access"
  value = {
    bronze = databricks_external_location.bronze.url
    silver = databricks_external_location.silver.url
    gold   = databricks_external_location.gold.url
  }
}

output "clusters" {
  value = {
    bronze = databricks_cluster.bronze_cluster.id
    silver = databricks_cluster.silver_cluster.id
    gold   = databricks_cluster.gold_cluster.id
  }
}
