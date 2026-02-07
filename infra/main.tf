# Bronze Cluster
resource "databricks_cluster" "bronze_cluster" {
  cluster_name            = "bronze-cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = "m5.large"
  data_security_mode      = "SINGLE_USER"
  autotermination_minutes = 20
  
  spark_conf = {
    "spark.databricks.delta.preview.enabled" = "true"
    "spark.databricks.cluster.profile"       = "singleNode"
    "spark.master"                           = "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  aws_attributes {
    availability           = "SPOT_WITH_FALLBACK"
    zone_id                = "auto"
    first_on_demand        = 1
    spot_bid_price_percent = 100
    instance_profile_arn   = databricks_instance_profile.s3_access.id
  }
}

# Silver Cluster
resource "databricks_cluster" "silver_cluster" {
  cluster_name            = "silver-cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = "m5.large"
  data_security_mode      = "SINGLE_USER"
  autotermination_minutes = 20
  
  spark_conf = {
    "spark.databricks.delta.preview.enabled" = "true"
    "spark.databricks.cluster.profile"       = "singleNode"
    "spark.master"                           = "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  aws_attributes {
    availability           = "SPOT_WITH_FALLBACK"
    zone_id                = "auto"
    first_on_demand        = 1
    spot_bid_price_percent = 100
    instance_profile_arn   = databricks_instance_profile.s3_access.id
  }
}

# Gold Cluster
resource "databricks_cluster" "gold_cluster" {
  cluster_name            = "gold-cluster"
  spark_version           = data.databricks_spark_version.latest_lts.id
  node_type_id            = "m5.large"
  data_security_mode      = "SINGLE_USER"
  autotermination_minutes = 20
  
  spark_conf = {
    "spark.databricks.delta.preview.enabled" = "true"
    "spark.databricks.cluster.profile"       = "singleNode"
    "spark.master"                           = "local[*]"
  }

  custom_tags = {
    "ResourceClass" = "SingleNode"
  }

  aws_attributes {
    availability           = "SPOT_WITH_FALLBACK"
    zone_id                = "auto"
    first_on_demand        = 1
    spot_bid_price_percent = 100
    instance_profile_arn   = databricks_instance_profile.s3_access.id
  }
}