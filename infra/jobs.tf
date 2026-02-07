# ----------------------------------------------------------------------------
# Databricks Job - MCO Pipeline Orchestration
# ----------------------------------------------------------------------------

resource "databricks_job" "mco_pipeline" {
  name = "MCO-Medallion-Pipeline"
  
  task {
    task_key = "bronze_extraction"
    existing_cluster_id = databricks_cluster.bronze_cluster.id
    
    spark_python_task {
      python_file = "scraping/mco_extractor.py"
      parameters  = [
        "--source-url", "https://ckan.pbh.gov.br/dataset/7ae4d4b4-6b52-4042-b021-0935a1db3814/resource/123b7a8a-ceb1-4f8c-9ec6-9ce76cdf9aab/download/mco-09-2025.csv",
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
  
  task {
    task_key = "silver_refinement"
    depends_on { task_key = "bronze_extraction" }
    existing_cluster_id = databricks_cluster.silver_cluster.id
    
    spark_python_task {
      python_file = "pipelines/silver_refinement.py"
      parameters  = [
        "--bronze-table", "${var.catalog_name}.${var.bronze_schema}.mco_raw",
        "--silver-table", "${var.catalog_name}.${var.silver_schema}.mco_clean"
      ]
    }
  }
  
  task {
    task_key = "gold_aggregations"
    depends_on { task_key = "silver_refinement" }
    existing_cluster_id = databricks_cluster.gold_cluster.id
    
    spark_python_task {
      python_file = "pipelines/gold_aggregations.py"
      parameters  = [
        "--silver-table", "${var.catalog_name}.${var.silver_schema}.mco_clean",
        "--gold-table", "${var.catalog_name}.${var.gold_schema}.fact_passageiros"
      ]
    }
  }
  
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
