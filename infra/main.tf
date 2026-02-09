# ============================================================================
# Databricks Cluster - Unified Processing
# ============================================================================

resource "databricks_cluster" "processing_cluster" {
  cluster_name            = "mco-processing-cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = "i3.xlarge"
  data_security_mode      = "SINGLE_USER"
  autotermination_minutes = 20
  num_workers             = 0

  spark_conf = {
    "spark.databricks.delta.preview.enabled" = "true"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
    "Layer"         = "Unified"
  }

  aws_attributes {
    zone_id                = "us-east-2a"
    availability           = "SPOT_WITH_FALLBACK"
    first_on_demand        = 1
    spot_bid_price_percent = 100
    ebs_volume_count       = 1
    ebs_volume_size        = 32
    ebs_volume_type        = "GENERAL_PURPOSE_SSD"

    subnet_id            = aws_subnet.databricks.id
    security_groups      = [aws_security_group.databricks.id]
    instance_profile_arn = aws_iam_instance_profile.databricks_s3_access.arn
  }
}

# Output do cluster ID para depois
output "processing_cluster_id" {
  value = databricks_cluster.processing_cluster.id
}
