# ============================================================================
# Terraform Import Blocks (Automated Adoption)
# Use these to import existing resources into the state without local CLI.
# ============================================================================

# S3 Bucket
import {
  to = aws_s3_bucket.databricks_data
  id = "case-be-analytic"
}

# Unity Catalog Schemas
import {
  to = databricks_schema.bronze
  id = "mco_catalog.bronze"
}

import {
  to = databricks_schema.silver
  id = "mco_catalog.silver"
}

import {
  to = databricks_schema.gold
  id = "mco_catalog.gold"
}

# IAM Resources
import {
  to = aws_iam_role.databricks_s3_access
  id = "databricks-s3-access-role"
}

import {
  to = aws_iam_instance_profile.databricks_s3
  id = "databricks-s3-instance-profile"
}

# Unity Catalog Resources
import {
  to = databricks_storage_credential.s3_credential
  id = "s3-storage-credential"
}
