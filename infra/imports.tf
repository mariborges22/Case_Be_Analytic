# ============================================================================
# Terraform Import Blocks (Automated Adoption)
# Use these to import existing resources into the state without local CLI.
# ============================================================================

# S3 Bucket
import {
  to = aws_s3_bucket.databricks_data
  id = "databricks-mco-lakehouse"
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
