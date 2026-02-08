# imports.tf - VERSÃO LIMPA
# ============================================================================
# Imports apenas para recursos que REALMENTE vamos gerenciar via Terraform
# ============================================================================

# Importar S3 bucket se já existir
import {
  id = "databricks-mco-lakehouse"
  to = aws_s3_bucket.databricks_data
}

# Importar external locations APENAS se já existirem
import {
  id = "db_s3_external_databricks-s3-ingest-9b92b"
  to = databricks_external_location.bronze
}

# Se não existirem, comentar estes blocos:

# import {
#   id = "bronze-location"
#   to = databricks_external_location.bronze
# }
# 
# import {
#   id = "silver-location"
#   to = databricks_external_location.silver
# }
# 
# import {
#   id = "gold-location"
#   to = databricks_external_location.gold
# }
