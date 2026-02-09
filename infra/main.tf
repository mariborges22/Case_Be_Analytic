# ============================================================================
# Databricks Cluster - Unified Processing
# ============================================================================

resource "databricks_cluster" "processing_cluster" {
  cluster_name            = "mco-processing-cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = "m5.large"
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
    ebs_volume_count = 1
    ebs_volume_size  = 32
    ebs_volume_type  = "GENERAL_PURPOSE_SSD"
  }
}

# Output do cluster ID para depois
output "processing_cluster_id" {
  value = databricks_cluster.processing_cluster.id
}
