# ----------------------------------------------------------------------------
# Compute Resources (Clusters) - AWS Config accessing Azure Storage
# ----------------------------------------------------------------------------

resource "databricks_cluster" "bronze_cluster" {
  cluster_name            = var.bronze_cluster_name
  spark_version           = var.cluster_spark_version
  node_type_id            = "i3.xlarge" # Bypass EBS requirement
  autotermination_minutes = var.cluster_autotermination_minutes
  
  autoscale {
    min_workers = var.cluster_min_workers
    max_workers = var.cluster_max_workers
  }
  
  runtime_engine     = var.enable_photon ? "PHOTON" : "STANDARD"
  data_security_mode = "USER_ISOLATION"

  aws_attributes {
    availability = "ON_DEMAND"
  }
  
  spark_conf = {
    "fs.azure.account.auth.type"                                = "OAuth"
    "fs.azure.account.oauth.provider.type"                      = "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
    "fs.azure.account.oauth2.client.id"                         = "{{secrets/azure-storage-scope/${databricks_secret.azure_client_id.key}}}"
    "fs.azure.account.oauth2.client.secret"                     = "{{secrets/azure-storage-scope/${databricks_secret.azure_client_secret.key}}}"
    "fs.azure.account.oauth2.client.endpoint"                   = "https://login.microsoftonline.com/{{secrets/azure-storage-scope/${databricks_secret.azure_tenant_id.key}}}/oauth2/token"

    "spark.databricks.delta.preview.enabled"           = "true"
    "spark.databricks.delta.optimizeWrite.enabled"     = var.enable_delta_optimize ? "true" : "false"
    "spark.databricks.delta.autoCompact.enabled"       = var.enable_delta_auto_compact ? "true" : "false"
    "spark.databricks.delta.zorder.enabled"            = var.enable_zorder ? "true" : "false"
    "spark.databricks.delta.properties.defaults.enableChangeDataFeed" = "true"
    "spark.sql.files.maxPartitionBytes"                = "134217728"
  }
  
  spark_env_vars = {
    CATALOG_NAME               = data.databricks_catalog.mco_catalog.name
    SCHEMA_NAME                = databricks_schema.bronze.name
    LAYER                      = "bronze"
    ENVIRONMENT                = var.environment
    DATABRICKS_CLIENT_ID       = var.databricks_client_id
    DATABRICKS_CLIENT_SECRET   = var.databricks_client_secret
  }
  
  custom_tags = {
    Layer       = "bronze"
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
  
  lifecycle {
    ignore_changes = [spark_version]
  }
}

resource "databricks_cluster" "silver_cluster" {
  cluster_name            = var.silver_cluster_name
  spark_version           = var.cluster_spark_version
  node_type_id            = "i3.xlarge"
  autotermination_minutes = var.cluster_autotermination_minutes
  
  autoscale {
    min_workers = var.cluster_min_workers
    max_workers = var.cluster_max_workers
  }
  
  runtime_engine     = var.enable_photon ? "PHOTON" : "STANDARD"
  data_security_mode = "USER_ISOLATION"

  aws_attributes {
    availability = "ON_DEMAND"
  }
  
  spark_conf = {
    "fs.azure.account.auth.type"                                = "OAuth"
    "fs.azure.account.oauth.provider.type"                      = "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
    "fs.azure.account.oauth2.client.id"                         = "{{secrets/azure-storage-scope/${databricks_secret.azure_client_id.key}}}"
    "fs.azure.account.oauth2.client.secret"                     = "{{secrets/azure-storage-scope/${databricks_secret.azure_client_secret.key}}}"
    "fs.azure.account.oauth2.client.endpoint"                   = "https://login.microsoftonline.com/{{secrets/azure-storage-scope/${databricks_secret.azure_tenant_id.key}}}/oauth2/token"

    "spark.databricks.delta.preview.enabled"           = "true"
    "spark.databricks.delta.optimizeWrite.enabled"     = var.enable_delta_optimize ? "true" : "false"
    "spark.databricks.delta.autoCompact.enabled"       = var.enable_delta_auto_compact ? "true" : "false"
    "spark.databricks.delta.zorder.enabled"            = var.enable_zorder ? "true" : "false"
    "spark.databricks.delta.properties.defaults.enableChangeDataFeed" = "true"
    "spark.sql.adaptive.enabled"                       = "true"
    "spark.sql.adaptive.coalescePartitions.enabled"    = "true"
  }
  
  spark_env_vars = {
    CATALOG_NAME               = data.databricks_catalog.mco_catalog.name
    SCHEMA_NAME                = databricks_schema.silver.name
    LAYER                      = "silver"
    ENVIRONMENT                = var.environment
    DATABRICKS_CLIENT_ID       = var.databricks_client_id
    DATABRICKS_CLIENT_SECRET   = var.databricks_client_secret
  }
  
  custom_tags = {
    Layer       = "silver"
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
  
  lifecycle {
    ignore_changes = [default_tags, spark_version]
  }
}

resource "databricks_cluster" "gold_cluster" {
  cluster_name            = var.gold_cluster_name
  spark_version           = var.cluster_spark_version
  node_type_id            = "i3.xlarge"
  autotermination_minutes = var.cluster_autotermination_minutes
  
  autoscale {
    min_workers = var.cluster_min_workers
    max_workers = var.cluster_max_workers
  }
  
  runtime_engine     = var.enable_photon ? "PHOTON" : "STANDARD"
  data_security_mode = "USER_ISOLATION"

  aws_attributes {
    availability = "ON_DEMAND"
  }
  
  spark_conf = {
    "fs.azure.account.auth.type"                                = "OAuth"
    "fs.azure.account.oauth.provider.type"                      = "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
    "fs.azure.account.oauth2.client.id"                         = "{{secrets/azure-storage-scope/${databricks_secret.azure_client_id.key}}}"
    "fs.azure.account.oauth2.client.secret"                     = "{{secrets/azure-storage-scope/${databricks_secret.azure_client_secret.key}}}"
    "fs.azure.account.oauth2.client.endpoint"                   = "https://login.microsoftonline.com/{{secrets/azure-storage-scope/${databricks_secret.azure_tenant_id.key}}}/oauth2/token"

    "spark.databricks.delta.preview.enabled"           = "true"
    "spark.databricks.delta.optimizeWrite.enabled"     = var.enable_delta_optimize ? "true" : "false"
    "spark.databricks.delta.autoCompact.enabled"       = var.enable_delta_auto_compact ? "true" : "false"
    "spark.databricks.delta.zorder.enabled"            = var.enable_zorder ? "true" : "false"
    "spark.databricks.delta.properties.defaults.enableChangeDataFeed" = "true"
    "spark.sql.adaptive.enabled"                       = "true"
    "spark.sql.adaptive.coalescePartitions.enabled"    = "true"
    "spark.sql.adaptive.skewJoin.enabled"              = "true"
  }
  
  spark_env_vars = {
    CATALOG_NAME               = data.databricks_catalog.mco_catalog.name
    SCHEMA_NAME                = databricks_schema.gold.name
    LAYER                      = "gold"
    ENVIRONMENT                = var.environment
    DATABRICKS_CLIENT_ID       = var.databricks_client_id
    DATABRICKS_CLIENT_SECRET   = var.databricks_client_secret
  }
  
  custom_tags = {
    Layer       = "gold"
    Environment = var.environment
    Project     = var.project_name
    Owner       = var.owner
    CostCenter  = var.cost_center
  }
  
  lifecycle {
    ignore_changes = [default_tags, spark_version]
  }
}
