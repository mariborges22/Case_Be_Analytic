# Storage Credential para S3
resource "databricks_storage_credential" "s3_credential" {
  name = "s3-storage-credential"
  
  aws_iam_role {
    role_arn = aws_iam_role.databricks_s3_access.arn
  }
  
  comment = "S3 access for Unity Catalog"

  lifecycle {
    prevent_destroy = true
  }
}

# External Locations
resource "databricks_external_location" "bronze" {
  name            = "bronze-location"
  url             = "s3://${data.aws_s3_bucket.databricks_data.id}/bronze"
  credential_name = databricks_storage_credential.s3_credential.name
  comment         = "Bronze layer storage"
}

resource "databricks_external_location" "silver" {
  name            = "silver-location"
  url             = "s3://${data.aws_s3_bucket.databricks_data.id}/silver"
  credential_name = databricks_storage_credential.s3_credential.name
  comment         = "Silver layer storage"
}

resource "databricks_external_location" "gold" {
  name            = "gold-location"
  url             = "s3://${data.aws_s3_bucket.databricks_data.id}/gold"
  credential_name = databricks_storage_credential.s3_credential.name
  comment         = "Gold layer storage"
}