terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.50.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "databricks" {
  # Workspace-level provider
  # Configured via env vars: DATABRICKS_HOST, DATABRICKS_TOKEN
}

provider "databricks" {
  alias      = "account"
  host       = "https://accounts.cloud.databricks.com"
  account_id = var.databricks_account_id
  # Authentication via env vars or ~/.databrickscfg
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}