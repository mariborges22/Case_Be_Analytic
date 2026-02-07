# ----------------------------------------------------------------------------
# Databricks Job - MCO Pipeline Orchestration
# ----------------------------------------------------------------------------

resource "databricks_job" "mco_pipeline" {
  name = "MCO-Medallion-Pipeline"

  # Common cluster configuration for all tasks
  # This makes each task independent and easier to debug
  
  task {
    task_key = "bronze_extraction"
    
    new_cluster {
      num_workers   = 1 # Job Clusters can be fixed size for predictable cost
      spark_version = var.cluster_spark_version
      node_type_id  = "i3.xlarge"
      
      runtime_engine     = "STANDARD"
      data_security_mode = "USER_ISOLATION"

      aws_attributes {
        availability = "ON_DEMAND"
      }

      spark_conf = {
        "fs.azure.account.auth.type"                = "OAuth"
        "fs.azure.account.oauth.provider.type"      = "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
        "fs.azure.account.oauth2.client.id"         = "{{secrets/azure-storage-scope/azure-client-id}}"
        "fs.azure.account.oauth2.client.secret"     = "{{secrets/azure-storage-scope/azure-client-secret}}"
        "fs.azure.account.oauth2.client.endpoint"   = "https://login.microsoftonline.com/{{secrets/azure-storage-scope/azure-tenant-id}}/oauth2/token"
      }
    }
    
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
    
    new_cluster {
      num_workers   = 1
      spark_version = var.cluster_spark_version
      node_type_id  = "i3.xlarge"
      
      runtime_engine     = "STANDARD"
      data_security_mode = "USER_ISOLATION"

      aws_attributes {
        availability = "ON_DEMAND"
      }

      spark_conf = {
        "fs.azure.account.auth.type"            = "OAuth"
        "fs.azure.account.oauth.provider.type"  = "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
        "fs.azure.account.oauth2.client.id"     = "{{secrets/azure-storage-scope/azure-client-id}}"
        "fs.azure.account.oauth2.client.secret" = "{{secrets/azure-storage-scope/azure-client-secret}}"
        "fs.azure.account.oauth2.client.endpoint" = "https://login.microsoftonline.com/{{secrets/azure-storage-scope/azure-tenant-id}}/oauth2/token"
      }
    }
    
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
    
    new_cluster {
      num_workers   = 1
      spark_version = var.cluster_spark_version
      node_type_id  = "i3.xlarge"
      
      runtime_engine     = "STANDARD"
      data_security_mode = "USER_ISOLATION"

      aws_attributes {
        availability = "ON_DEMAND"
      }

      spark_conf = {
        "fs.azure.account.auth.type"            = "OAuth"
        "fs.azure.account.oauth.provider.type"  = "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider"
        "fs.azure.account.oauth2.client.id"     = "{{secrets/azure-storage-scope/azure-client-id}}"
        "fs.azure.account.oauth2.client.secret" = "{{secrets/azure-storage-scope/azure-client-secret}}"
        "fs.azure.account.oauth2.client.endpoint" = "https://login.microsoftonline.com/{{secrets/azure-storage-scope/azure-tenant-id}}/oauth2/token"
      }
    }
    
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
