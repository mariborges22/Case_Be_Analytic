terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "1.30.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Ajuste conforme necessário
}

provider "databricks" {
  # Configurado via env vars:
  # DATABRICKS_HOST
  # DATABRICKS_CLIENT_ID
  # DATABRICKS_CLIENT_SECRET
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}