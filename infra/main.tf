# ============================================================================
# Databricks Data Lakehouse - Main Infrastructure
# Arquitetura Medalhão (Bronze, Prata, Ouro) com Unity Catalog
# ============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.40"
    }
  }
}

# ----------------------------------------------------------------------------
# Provider Configuration
# ----------------------------------------------------------------------------

provider "databricks" {
  host          = var.databricks_host
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

# ----------------------------------------------------------------------------
# Unity Catalog - Main Catalog
# ----------------------------------------------------------------------------

resource "databricks_catalog" "mco_catalog" {
  name    = var.catalog_name
  comment = "MCO Catalog - Arquitetura Medalhão para dados de Mobilidade e Cidadania Operacional de Belo Horizonte"
  
  properties = {
    environment  = var.environment
    project      = var.project_name
    owner        = var.owner
    cost_center  = var.cost_center
    architecture = "medallion"
    data_source  = "mco_belo_horizonte"
  }
  
  # CRITICAL: Prevent accidental deletion of the entire catalog
  lifecycle {
    prevent_destroy = true
  }
}

# ----------------------------------------------------------------------------
# Bronze Layer (Raw Data) - Immutable Ingestion
# ----------------------------------------------------------------------------

resource "databricks_schema" "bronze" {
  catalog_name = databricks_catalog.mco_catalog.name
  name         = var.bronze_schema
  comment      = "Camada Bronze: Dados brutos e imutáveis do MCO (ELT - Extract & Load)"
  
  properties = {
    layer        = "bronze"
    data_type    = "raw"
    is_immutable = "true"
    description  = "Ingestão de dados MCO originais sem transformação"
  }
  
  # CRITICAL: Prevent accidental deletion of bronze schema
  lifecycle {
    prevent_destroy = true
  }
}

# ----------------------------------------------------------------------------
# Silver Layer (Validated Data) - Single Source of Truth
# ----------------------------------------------------------------------------

resource "databricks_schema" "silver" {
  catalog_name = databricks_catalog.mco_catalog.name
  name         = var.silver_schema
  comment      = "Camada Prata: Dados limpos, validados e desduplicados (ELT - Transform)"
  
  properties = {
    layer       = "silver"
    data_type   = "validated"
    operations  = "cleaning,deduplication,normalization,null_handling"
    description = "Versão única da verdade (single source of truth)"
  }
  
  # CRITICAL: Prevent accidental deletion of silver schema
  lifecycle {
    prevent_destroy = true
  }
}

# ----------------------------------------------------------------------------
# Gold Layer (Enriched Data) - Business Aggregates
# ----------------------------------------------------------------------------

resource "databricks_schema" "gold" {
  catalog_name = databricks_catalog.mco_catalog.name
  name         = var.gold_schema
  comment      = "Camada Ouro: Agregados de negócio e modelagem dimensional (Star Schema)"
  
  properties = {
    layer        = "gold"
    data_type    = "aggregated"
    modeling     = "star_schema"
    optimization = "zorder,partitioning"
    description  = "Dados otimizados para consumo de negócio e analytics"
  }
  
  # CRITICAL: Prevent accidental deletion of gold schema
  lifecycle {
    prevent_destroy = true
  }
}

# ----------------------------------------------------------------------------
# Bronze Cluster - Raw Data Ingestion
# ----------------------------------------------------------------------------

resource "databricks_cluster" "bronze_cluster" {
  cluster_name            = var.bronze_cluster_name
  spark_version           = var.cluster_spark_version
  node_type_id            = var.cluster_node_type_id
  autotermination_minutes = var.cluster_autotermination_minutes
  
  autoscale {
    min_workers = var.cluster_min_workers
    max_workers = var.cluster_max_workers
  }
  
  # Photon engine for performance
  runtime_engine = var.enable_photon ? "PHOTON" : "STANDARD"
  
  # Unity Catalog security
  data_security_mode = var.data_security_mode
  
  # Spark configurations - PENDING REBOOT (não reinicia automaticamente)
  # Mudanças nestes parâmetros exigirão restart manual via UI/API
  spark_conf = {
    # Delta Lake optimizations
    "spark.databricks.delta.preview.enabled"           = "true"
    "spark.databricks.delta.optimizeWrite.enabled"     = var.enable_delta_optimize ? "true" : "false"
    "spark.databricks.delta.autoCompact.enabled"       = var.enable_delta_auto_compact ? "true" : "false"
    
    # Z-Ordering for performance
    "spark.databricks.delta.zorder.enabled"            = var.enable_zorder ? "true" : "false"
    
    # Bronze layer specific configs
    "spark.databricks.delta.properties.defaults.enableChangeDataFeed" = "true"
    "spark.sql.files.maxPartitionBytes"                = "134217728"  # 128MB
  }
  
  # Environment variables
  spark_env_vars = {
    CATALOG_NAME               = databricks_catalog.mco_catalog.name
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
  
  # Lifecycle: Ignore external changes to prevent unnecessary recreations
  lifecycle {
    ignore_changes = [
      # Ignore system-managed tags
      default_tags,
      # Ignore automatic version updates
      spark_version,
    ]
  }
}

# ----------------------------------------------------------------------------
# Silver Cluster - Data Cleaning & Validation
# ----------------------------------------------------------------------------

resource "databricks_cluster" "silver_cluster" {
  cluster_name            = var.silver_cluster_name
  spark_version           = var.cluster_spark_version
  node_type_id            = var.cluster_node_type_id
  autotermination_minutes = var.cluster_autotermination_minutes
  
  autoscale {
    min_workers = var.cluster_min_workers
    max_workers = var.cluster_max_workers
  }
  
  runtime_engine     = var.enable_photon ? "PHOTON" : "STANDARD"
  data_security_mode = var.data_security_mode
  
  spark_conf = {
    "spark.databricks.delta.preview.enabled"           = "true"
    "spark.databricks.delta.optimizeWrite.enabled"     = var.enable_delta_optimize ? "true" : "false"
    "spark.databricks.delta.autoCompact.enabled"       = var.enable_delta_auto_compact ? "true" : "false"
    "spark.databricks.delta.zorder.enabled"            = var.enable_zorder ? "true" : "false"
    
    # Silver layer specific configs for deduplication
    "spark.databricks.delta.properties.defaults.enableChangeDataFeed" = "true"
    "spark.sql.adaptive.enabled"                       = "true"
    "spark.sql.adaptive.coalescePartitions.enabled"    = "true"
  }
  
  spark_env_vars = {
    CATALOG_NAME               = databricks_catalog.mco_catalog.name
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
    ignore_changes = [
      default_tags,
      spark_version,
    ]
  }
}

# ----------------------------------------------------------------------------
# Gold Cluster - Business Aggregates & Star Schema
# ----------------------------------------------------------------------------

resource "databricks_cluster" "gold_cluster" {
  cluster_name            = var.gold_cluster_name
  spark_version           = var.cluster_spark_version
  node_type_id            = var.cluster_node_type_id
  autotermination_minutes = var.cluster_autotermination_minutes
  
  autoscale {
    min_workers = var.cluster_min_workers
    max_workers = var.cluster_max_workers
  }
  
  runtime_engine     = var.enable_photon ? "PHOTON" : "STANDARD"
  data_security_mode = var.data_security_mode
  
  spark_conf = {
    "spark.databricks.delta.preview.enabled"           = "true"
    "spark.databricks.delta.optimizeWrite.enabled"     = var.enable_delta_optimize ? "true" : "false"
    "spark.databricks.delta.autoCompact.enabled"       = var.enable_delta_auto_compact ? "true" : "false"
    "spark.databricks.delta.zorder.enabled"            = var.enable_zorder ? "true" : "false"
    
    # Gold layer specific configs for aggregations
    "spark.databricks.delta.properties.defaults.enableChangeDataFeed" = "true"
    "spark.sql.adaptive.enabled"                       = "true"
    "spark.sql.adaptive.coalescePartitions.enabled"    = "true"
    "spark.sql.adaptive.skewJoin.enabled"              = "true"
  }
  
  spark_env_vars = {
    CATALOG_NAME               = databricks_catalog.mco_catalog.name
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
    ignore_changes = [
      default_tags,
      spark_version,
    ]
  }
}

# ----------------------------------------------------------------------------
# Grants and Permissions (RBAC via Unity Catalog)
# ----------------------------------------------------------------------------

# Grant read access to all schemas for data analysts
resource "databricks_grants" "catalog_grants" {
  catalog = databricks_catalog.mco_catalog.name
  
  grant {
    principal  = "account users"
    privileges = ["USE_CATALOG", "USE_SCHEMA", "SELECT"]
  }
}

# Bronze schema: Only data engineers can write
resource "databricks_grants" "bronze_schema_grants" {
  schema = "${databricks_catalog.mco_catalog.name}.${databricks_schema.bronze.name}"
  
  grant {
    principal  = "data-engineers"
    privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  }
}

# Silver schema: Data engineers can write
resource "databricks_grants" "silver_schema_grants" {
  schema = "${databricks_catalog.mco_catalog.name}.${databricks_schema.silver.name}"
  
  grant {
    principal  = "data-engineers"
    privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  }
}

# Gold schema: Data engineers and analysts can read
resource "databricks_grants" "gold_schema_grants" {
  schema = "${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}"
  
  grant {
    principal  = "data-engineers"
    privileges = ["USE_SCHEMA", "SELECT", "MODIFY", "CREATE_TABLE"]
  }
  
  grant {
    principal  = "data-analysts"
    privileges = ["USE_SCHEMA", "SELECT"]
  }
}

# ----------------------------------------------------------------------------
# Databricks Job - MCO Pipeline Orchestration
# ----------------------------------------------------------------------------

resource "databricks_job" "mco_pipeline" {
  name = "MCO-Medallion-Pipeline"
  
  # Task 1: Bronze - Extract MCO Data
  task {
    task_key = "bronze_extraction"
    
    existing_cluster_id = databricks_cluster.bronze_cluster.id
    
    spark_python_task {
      python_file = "scraping/mco_extractor.py"
      parameters  = [
        "--source-url",
        "https://ckan.pbh.gov.br/dataset/7ae4d4b4-6b52-4042-b021-0935a1db3814/resource/123b7a8a-ceb1-4f8c-9ec6-9ce76cdf9aab/download/mco-09-2025.csv",
        "--catalog-name", var.catalog_name,
        "--schema-name", var.bronze_schema
      ]
    }
    
    library {
      pypi {
        package = "requests>=2.31.0"
      }
    }
  }
  
  # Task 2: Silver - Refine Data
  task {
    task_key = "silver_refinement"
    
    depends_on {
      task_key = "bronze_extraction"
    }
    
    existing_cluster_id = databricks_cluster.silver_cluster.id
    
    spark_python_task {
      python_file = "pipelines/silver_refinement.py"
      parameters  = [
        "--bronze-table", "${var.catalog_name}.${var.bronze_schema}.mco_raw",
        "--silver-table", "${var.catalog_name}.${var.silver_schema}.mco_clean"
      ]
    }
  }
  
  # Task 3: Gold - Create Aggregates
  task {
    task_key = "gold_aggregations"
    
    depends_on {
      task_key = "silver_refinement"
    }
    
    existing_cluster_id = databricks_cluster.gold_cluster.id
    
    spark_python_task {
      python_file = "pipelines/gold_aggregations.py"
      parameters  = [
        "--silver-table", "${var.catalog_name}.${var.silver_schema}.mco_clean",
        "--gold-table", "${var.catalog_name}.${var.gold_schema}.fact_passageiros"
      ]
    }
  }
  
  # Schedule: Daily at 2 AM
  schedule {
    quartz_cron_expression = "0 0 2 * * ?"
    timezone_id            = "America/Sao_Paulo"
  }
  
  email_notifications {
    on_failure = [var.owner]
  }
  
  tags = {
    Environment = var.environment
    Project     = var.project_name
    Pipeline    = "mco-medallion"
  }
}

