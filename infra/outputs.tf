# ============================================================================
# Databricks MCO Lakehouse - Outputs
# Arquitetura Medalhão - Recursos Provisionados para MCO (Mobilidade e Cidadania Operacional)
# ============================================================================

# ----------------------------------------------------------------------------
# Unity Catalog Outputs
# ----------------------------------------------------------------------------

output "mco_catalog_id" {
  description = "MCO Unity Catalog ID"
  value       = databricks_catalog.mco_catalog.id
}

output "mco_catalog_name" {
  description = "MCO Unity Catalog name for use in DABs and workflows"
  value       = databricks_catalog.mco_catalog.name
}

output "mco_catalog_full_name" {
  description = "MCO Unity Catalog fully qualified name"
  value       = databricks_catalog.mco_catalog.name
}

# ----------------------------------------------------------------------------
# Schema Outputs (Medallion Architecture)
# Padrão de nomenclatura: <camada>_mco_<entidade>
# ----------------------------------------------------------------------------

output "bronze_mco_schema_id" {
  description = "Bronze schema ID (raw MCO data layer)"
  value       = databricks_schema.bronze.id
}

output "bronze_mco_schema_name" {
  description = "Bronze schema fully qualified name for MCO raw data"
  value       = "${databricks_catalog.mco_catalog.name}.${databricks_schema.bronze.name}"
}

output "silver_mco_schema_id" {
  description = "Silver schema ID (validated MCO data layer)"
  value       = databricks_schema.silver.id
}

output "silver_mco_schema_name" {
  description = "Silver schema fully qualified name for MCO validated data"
  value       = "${databricks_catalog.mco_catalog.name}.${databricks_schema.silver.name}"
}

output "gold_mco_schema_id" {
  description = "Gold schema ID (aggregated MCO data layer)"
  value       = databricks_schema.gold.id
}

output "gold_mco_schema_name" {
  description = "Gold schema fully qualified name for MCO business aggregates"
  value       = "${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}"
}

# ----------------------------------------------------------------------------
# Cluster Outputs
# Padrão de nomenclatura: <camada>_mco_cluster_<atributo>
# ----------------------------------------------------------------------------

output "bronze_mco_cluster_id" {
  description = "Bronze cluster ID for MCO raw data ingestion"
  value       = databricks_cluster.bronze_cluster.id
  sensitive   = true
}

output "bronze_mco_cluster_name" {
  description = "Bronze cluster name for MCO data extraction"
  value       = databricks_cluster.bronze_cluster.cluster_name
}

output "silver_mco_cluster_id" {
  description = "Silver cluster ID for MCO data cleaning and validation"
  value       = databricks_cluster.silver_cluster.id
  sensitive   = true
}

output "silver_mco_cluster_name" {
  description = "Silver cluster name for MCO data refinement"
  value       = databricks_cluster.silver_cluster.cluster_name
}

output "gold_mco_cluster_id" {
  description = "Gold cluster ID for MCO business aggregates"
  value       = databricks_cluster.gold_cluster.id
  sensitive   = true
}

output "gold_mco_cluster_name" {
  description = "Gold cluster name for MCO analytics"
  value       = databricks_cluster.gold_cluster.cluster_name
}

# ----------------------------------------------------------------------------
# Configuration Information
# ----------------------------------------------------------------------------

output "photon_enabled" {
  description = "Whether Photon engine is enabled on MCO clusters"
  value       = var.enable_photon
}

output "data_security_mode" {
  description = "Data security mode applied to all MCO clusters"
  value       = var.data_security_mode
}

# ----------------------------------------------------------------------------
# Operational Warnings and Notes
# ----------------------------------------------------------------------------

output "cluster_restart_warning" {
  description = "IMPORTANT: Changes to spark_conf require manual cluster restart"
  value       = <<-EOT
    ⚠️  CLUSTER RESTART POLICY:
    
    This infrastructure uses a PENDING REBOOT strategy for cluster configurations.
    
    Any changes to the following will NOT auto-restart clusters:
    - spark_conf parameters
    - spark_env_vars
    - custom_tags
    
    To apply configuration changes:
    1. Run `terraform apply` to update the cluster configuration
    2. Manually restart clusters via Databricks UI or CLI:
       - databricks clusters restart --cluster-id <cluster_id>
    
    This prevents interruption of running jobs and allows scheduled maintenance windows.
    
    For immediate application in development, use:
    - databricks clusters restart --cluster-id ${databricks_cluster.bronze_cluster.id}
    - databricks clusters restart --cluster-id ${databricks_cluster.silver_cluster.id}
    - databricks clusters restart --cluster-id ${databricks_cluster.gold_cluster.id}
  EOT
}

output "delta_maintenance_commands" {
  description = "Commands for Delta table maintenance (OPTIMIZE and VACUUM) for MCO tables"
  value       = <<-EOT
    📊 DELTA TABLE MAINTENANCE COMMANDS (MCO Catalog):
    
    # OPTIMIZE: Compacts small files into fewer large files
    OPTIMIZE ${databricks_catalog.mco_catalog.name}.${databricks_schema.bronze.name}.mco_raw
    OPTIMIZE ${databricks_catalog.mco_catalog.name}.${databricks_schema.silver.name}.mco_clean ZORDER BY (LINHA, DATA)
    OPTIMIZE ${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}.fact_passageiros ZORDER BY (LINHA)
    
    # VACUUM: Removes old data files (default retention: 7 days)
    VACUUM ${databricks_catalog.mco_catalog.name}.${databricks_schema.bronze.name}.mco_raw RETAIN 168 HOURS
    VACUUM ${databricks_catalog.mco_catalog.name}.${databricks_schema.silver.name}.mco_clean RETAIN 168 HOURS
    VACUUM ${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}.fact_passageiros RETAIN 168 HOURS
    
    # Dimension Tables
    OPTIMIZE ${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}.dim_linha
    OPTIMIZE ${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}.dim_data ZORDER BY (ano, mes)
    
    ⚠️  Never run VACUUM with retention < 7 days in production without disabling time travel!
  EOT
}

output "mco_medallion_architecture_summary" {
  description = "Summary of MCO Medallion Architecture implementation"
  value       = {
    bronze = {
      schema      = "${databricks_catalog.mco_catalog.name}.${databricks_schema.bronze.name}"
      cluster_id  = databricks_cluster.bronze_cluster.id
      purpose     = "Raw MCO data ingestion from Belo Horizonte (immutable)"
      tables      = ["mco_raw"]
      protection  = "prevent_destroy = true"
    }
    silver = {
      schema      = "${databricks_catalog.mco_catalog.name}.${databricks_schema.silver.name}"
      cluster_id  = databricks_cluster.silver_cluster.id
      purpose     = "Cleaned and validated MCO data (single source of truth)"
      tables      = ["mco_clean"]
      protection  = "prevent_destroy = true"
    }
    gold = {
      schema      = "${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}"
      cluster_id  = databricks_cluster.gold_cluster.id
      purpose     = "MCO business aggregates and star schema"
      tables      = ["fact_passageiros", "dim_linha", "dim_data"]
      protection  = "prevent_destroy = true"
    }
  }
}

# ----------------------------------------------------------------------------
# Data Lineage Tracking
# ----------------------------------------------------------------------------

output "mco_data_lineage" {
  description = "MCO data lineage flow for governance and auditing"
  value       = {
    source = {
      url         = "https://ckan.pbh.gov.br/dataset/7ae4d4b4-6b52-4042-b021-0935a1db3814"
      description = "MCO - Mobilidade e Cidadania Operacional de Belo Horizonte"
      format      = "CSV"
    }
    bronze = {
      table       = "${databricks_catalog.mco_catalog.name}.${databricks_schema.bronze.name}.mco_raw"
      format      = "Delta"
      metadata    = ["_ingestion_timestamp", "_source_url", "_ingestion_date"]
    }
    silver = {
      table       = "${databricks_catalog.mco_catalog.name}.${databricks_schema.silver.name}.mco_clean"
      format      = "Delta"
      operations  = ["deduplication", "null_handling", "type_casting", "normalization"]
      metadata    = ["_processed_at"]
    }
    gold = {
      fact_table  = "${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}.fact_passageiros"
      dimensions  = [
        "${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}.dim_linha",
        "${databricks_catalog.mco_catalog.name}.${databricks_schema.gold.name}.dim_data"
      ]
      format      = "Delta"
      optimization = ["ZORDER BY LINHA", "PARTITION BY DATA"]
    }
  }
}

# ----------------------------------------------------------------------------
# Environment Context
# ----------------------------------------------------------------------------

output "environment" {
  description = "Current environment (dev, staging, prod)"
  value       = var.environment
}

output "project_name" {
  description = "Project name (MCO Pipeline)"
  value       = var.project_name
}
