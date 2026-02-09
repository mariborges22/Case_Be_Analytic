# ============================================================================
# External Locations - S3 paths for Medallion Architecture
# ============================================================================

resource "databricks_external_location" "bronze" {
  name            = "db_s3_external_databricks-s3-ingest-9b92b"
  url             = "s3://databricks-mco-lakehouse-v2/bronze"
  credential_name = data.databricks_storage_credential.s3_storage_credential.name
  comment         = "Bronze layer - raw, immutable data from MCO"

  lifecycle {
    ignore_changes = [
      url,
      credential_name
    ]
  }

  depends_on = [
    aws_s3_bucket.databricks_data,
    data.databricks_storage_credential.s3_storage_credential
  ]
}

# Para silver e gold, comentados temporariamente conforme solicitado:
/*
resource "databricks_external_location" "silver" {
  name            = "silver-location"
  url             = "s3://${aws_s3_bucket.databricks_data.id}/silver"
  credential_name = data.databricks_storage_credential.s3_storage_credential.name
  comment         = "Silver layer - cleaned, validated MCO data"
  
  depends_on = [aws_s3_bucket.databricks_data]
}

resource "databricks_external_location" "gold" {
  name            = "gold-location"
  url             = "s3://${aws_s3_bucket.databricks_data.id}/gold"
  credential_name = data.databricks_storage_credential.s3_storage_credential.name
  comment         = "Gold layer - business aggregates and analytics"
  
  depends_on = [aws_s3_bucket.databricks_data]
}
*/
