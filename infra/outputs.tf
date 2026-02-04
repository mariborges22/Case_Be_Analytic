# ============================================================================
# Databricks Data Lakehouse - Outputs
# Arquitetura Medalhão - Recursos Provisionados
# ============================================================================

# ----------------------------------------------------------------------------
# Unity Catalog Outputs
# ----------------------------------------------------------------------------

output "catalog_id" {
  description = "Unity Catalog ID"
  value       = databricks_catalog.sus_lakehouse.id
}

output "catalog_name" {
  description = "Unity Catalog name for use in DABs and workflows"
  value       = databricks_catalog.sus_lakehouse.name
}

output "catalog_full_name" {
  description = "Unity Catalog fully qualified name"
  value       = databricks_catalog.sus_lakehouse.name
}

# ----------------------------------------------------------------------------
# Schema Outputs (Medallion Architecture)
# ----------------------------------------------------------------------------

output "bronze_schema_id" {
  description = "Bronze schema ID (raw data layer)"
  value       = databricks_schema.bronze.id
}

output "bronze_schema_name" {
  description = "Bronze schema fully qualified name"
  value       = "${databricks_catalog.sus_lakehouse.name}.${databricks_schema.bronze.name}"
}

output "silver_schema_id" {
  description = "Silver schema ID (validated data layer)"
  value       = databricks_schema.silver.id
}

output "silver_schema_name" {
  description = "Silver schema fully qualified name"
  value       = "${databricks_catalog.sus_lakehouse.name}.${databricks_schema.silver.name}"
}

output "gold_schema_id" {
  description = "Gold schema ID (aggregated data layer)"
  value       = databricks_schema.gold.id
}

output "gold_schema_name" {
  description = "Gold schema fully qualified name"
  value       = "${databricks_catalog.sus_lakehouse.name}.${databricks_schema.gold.name}"
}

# ----------------------------------------------------------------------------
# Cluster Outputs
# ----------------------------------------------------------------------------

output "bronze_cluster_id" {
  description = "Bronze cluster ID for raw data ingestion"
  value       = databricks_cluster.bronze_cluster.id
  sensitive   = true
}

output "bronze_cluster_name" {
  description = "Bronze cluster name"
  value       = databricks_cluster.bronze_cluster.cluster_name
}

output "silver_cluster_id" {
  description = "Silver cluster ID for data cleaning and validation"
  value       = databricks_cluster.silver_cluster.id
  sensitive   = true
}

output "silver_cluster_name" {
  description = "Silver cluster name"
  value       = databricks_cluster.silver_cluster.cluster_name
}

output "gold_cluster_id" {
  description = "Gold cluster ID for business aggregates"
  value       = databricks_cluster.gold_cluster.id
  sensitive   = true
}

output "gold_cluster_name" {
  description = "Gold cluster name"
  value       = databricks_cluster.gold_cluster.cluster_name
}

# ----------------------------------------------------------------------------
# Configuration Information
# ----------------------------------------------------------------------------

output "photon_enabled" {
  description = "Whether Photon engine is enabled on clusters"
  value       = var.enable_photon
}

output "data_security_mode" {
  description = "Data security mode applied to all clusters"
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
  description = "Commands for Delta table maintenance (OPTIMIZE and VACUUM)"
  value       = <<-EOT
    📊 DELTA TABLE MAINTENANCE COMMANDS:
    
    # OPTIMIZE: Compacts small files into fewer large files
    OPTIMIZE ${databricks_catalog.sus_lakehouse.name}.${databricks_schema.bronze.name}.<table_name>
    OPTIMIZE ${databricks_catalog.sus_lakehouse.name}.${databricks_schema.silver.name}.<table_name> ZORDER BY (column1, column2)
    OPTIMIZE ${databricks_catalog.sus_lakehouse.name}.${databricks_schema.gold.name}.<table_name> ZORDER BY (date_column)
    
    # VACUUM: Removes old data files (default retention: 7 days)
    VACUUM ${databricks_catalog.sus_lakehouse.name}.${databricks_schema.bronze.name}.<table_name> RETAIN 168 HOURS
    VACUUM ${databricks_catalog.sus_lakehouse.name}.${databricks_schema.silver.name}.<table_name> RETAIN 168 HOURS
    VACUUM ${databricks_catalog.sus_lakehouse.name}.${databricks_schema.gold.name}.<table_name> RETAIN 168 HOURS
    
    ⚠️  Never run VACUUM with retention < 7 days in production without disabling time travel!
  EOT
}

output "medallion_architecture_summary" {
  description = "Summary of Medallion Architecture implementation"
  value       = {
    bronze = {
      schema      = "${databricks_catalog.sus_lakehouse.name}.${databricks_schema.bronze.name}"
      cluster_id  = databricks_cluster.bronze_cluster.id
      purpose     = "Raw data ingestion (immutable)"
      protection  = "prevent_destroy = true"
    }
    silver = {
      schema      = "${databricks_catalog.sus_lakehouse.name}.${databricks_schema.silver.name}"
      cluster_id  = databricks_cluster.silver_cluster.id
      purpose     = "Cleaned and validated data (single source of truth)"
      protection  = "prevent_destroy = true"
    }
    gold = {
      schema      = "${databricks_catalog.sus_lakehouse.name}.${databricks_schema.gold.name}"
      cluster_id  = databricks_cluster.gold_cluster.id
      purpose     = "Business aggregates and star schema"
      protection  = "prevent_destroy = true"
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
  description = "Project name"
  value       = var.project_name
}
