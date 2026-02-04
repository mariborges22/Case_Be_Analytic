# ============================================================================
# Databricks Data Lakehouse - Variables
# Arquitetura Medalhão (Bronze, Prata, Ouro)
# ============================================================================

# ----------------------------------------------------------------------------
# Databricks Connection
# ----------------------------------------------------------------------------

variable "databricks_host" {
  description = "Databricks workspace URL (e.g., https://adb-123456789.azuredatabricks.net)"
  type        = string
  sensitive   = true
}

variable "databricks_token" {
  description = "Databricks personal access token or service principal token"
  type        = string
  sensitive   = true
}

variable "databricks_account_id" {
  description = "Databricks account ID for Unity Catalog management"
  type        = string
  sensitive   = true
}

# ----------------------------------------------------------------------------
# Unity Catalog Configuration
# ----------------------------------------------------------------------------

variable "catalog_name" {
  description = "Name of the Unity Catalog for SUS Lakehouse"
  type        = string
  default     = "sus_lakehouse"
}

variable "metastore_id" {
  description = "Unity Catalog Metastore ID (if pre-existing)"
  type        = string
  default     = ""
}

variable "storage_credential_name" {
  description = "Name of the storage credential for external locations"
  type        = string
  default     = "sus_storage_credential"
}

# ----------------------------------------------------------------------------
# Medallion Architecture - Schema Names
# ----------------------------------------------------------------------------

variable "bronze_schema" {
  description = "Bronze layer schema name (raw, immutable data)"
  type        = string
  default     = "bronze"
}

variable "silver_schema" {
  description = "Silver layer schema name (cleaned, validated data)"
  type        = string
  default     = "silver"
}

variable "gold_schema" {
  description = "Gold layer schema name (business aggregates, star schema)"
  type        = string
  default     = "gold"
}

# ----------------------------------------------------------------------------
# Cluster Configuration
# ----------------------------------------------------------------------------

variable "bronze_cluster_name" {
  description = "Name of the Bronze layer processing cluster"
  type        = string
  default     = "sus-bronze-cluster"
}

variable "silver_cluster_name" {
  description = "Name of the Silver layer processing cluster"
  type        = string
  default     = "sus-silver-cluster"
}

variable "gold_cluster_name" {
  description = "Name of the Gold layer processing cluster"
  type        = string
  default     = "sus-gold-cluster"
}

variable "cluster_node_type_id" {
  description = "Node type for Databricks clusters (Azure: Standard_DS3_v2, AWS: i3.xlarge)"
  type        = string
  default     = "Standard_DS3_v2"
}

variable "cluster_spark_version" {
  description = "Spark version for clusters (use LTS version)"
  type        = string
  default     = "13.3.x-scala2.12"
}

variable "enable_photon" {
  description = "Enable Photon engine for performance optimization"
  type        = bool
  default     = true
}

variable "cluster_autotermination_minutes" {
  description = "Auto-termination time in minutes for idle clusters"
  type        = number
  default     = 30
}

variable "cluster_min_workers" {
  description = "Minimum number of workers for autoscaling"
  type        = number
  default     = 1
}

variable "cluster_max_workers" {
  description = "Maximum number of workers for autoscaling"
  type        = number
  default     = 4
}

# ----------------------------------------------------------------------------
# Data Security & Governance
# ----------------------------------------------------------------------------

variable "data_security_mode" {
  description = "Cluster data security mode for Unity Catalog"
  type        = string
  default     = "USER_ISOLATION"
  
  validation {
    condition     = contains(["USER_ISOLATION", "SINGLE_USER"], var.data_security_mode)
    error_message = "Data security mode must be either USER_ISOLATION or SINGLE_USER."
  }
}

# ----------------------------------------------------------------------------
# Tags and Metadata
# ----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "sus-log-engine"
}

variable "owner" {
  description = "Owner or team responsible for the infrastructure"
  type        = string
  default     = "data-engineering-team"
}

variable "cost_center" {
  description = "Cost center for billing and chargeback"
  type        = string
  default     = "analytics"
}

# ----------------------------------------------------------------------------
# Delta Lake Configuration
# ----------------------------------------------------------------------------

variable "enable_delta_optimize" {
  description = "Enable automatic OPTIMIZE for Delta tables"
  type        = bool
  default     = true
}

variable "enable_delta_auto_compact" {
  description = "Enable auto-compaction for Delta tables"
  type        = bool
  default     = true
}

variable "enable_zorder" {
  description = "Enable Z-Ordering for Delta tables"
  type        = bool
  default     = true
}
