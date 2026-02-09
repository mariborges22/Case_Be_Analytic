terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.54"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Provider AWS (us-east-2 - mesma região do Databricks)
provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

# Provider Databricks (us-east-2)
provider "databricks" {
  host       = var.databricks_host
  token      = var.databricks_token
}

data "databricks_spark_version" "latest_lts" {
  long_term_support = true
}