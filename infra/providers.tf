terraform {
  required_version = ">= 1.0"
  
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
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
  # DATABRICKS_TOKEN
}