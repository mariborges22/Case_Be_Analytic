# External Locations
resource "databricks_external_location" "bronze" {
  name            = "bronze-location"
  url             = "s3://${aws_s3_bucket.databricks_data.id}/bronze"
  credential_name = data.databricks_storage_credential.s3_credential.name
  comment         = "Bronze layer storage"
  depends_on      = [aws_s3_bucket.databricks_data]
}

resource "databricks_external_location" "silver" {
  name            = "silver-location"
  url             = "s3://${aws_s3_bucket.databricks_data.id}/silver"
  credential_name = data.databricks_storage_credential.s3_credential.name
  comment         = "Silver layer storage"
  depends_on      = [aws_s3_bucket.databricks_data]
}

resource "databricks_external_location" "gold" {
  name            = "gold-location"
  url             = "s3://${aws_s3_bucket.databricks_data.id}/gold"
  credential_name = data.databricks_storage_credential.s3_credential.name
  comment         = "Gold layer storage"
  depends_on      = [aws_s3_bucket.databricks_data]
}