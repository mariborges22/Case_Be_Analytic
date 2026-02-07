# ============================================================================
# Databricks MCO Lakehouse - Outputs (AWS Only)
# ============================================================================

output "s3_bucket_name" {
  value       = aws_s3_bucket.databricks_data.id
  description = "Nome do bucket S3 para os dados do Lakehouse"
}

output "instance_profile_arn" {
  value       = aws_iam_instance_profile.databricks_s3.arn
  description = "ARN do Instance Profile usado para acesso ao S3"
}

output "bronze_cluster_id" {
  value       = databricks_cluster.bronze_cluster.id
  description = "ID do Cluster Bronze"
}

output "silver_cluster_id" {
  value       = databricks_cluster.silver_cluster.id
  description = "ID do Cluster Silver"
}

output "gold_cluster_id" {
  value       = databricks_cluster.gold_cluster.id
  description = "ID do Cluster Gold"
}

output "job_id" {
  value       = databricks_job.mco_pipeline.id
  description = "ID do Job de Orquestração MCO"
}

output "medallion_architecture_summary" {
  description = "Resumo da arquitetura Medalhão na AWS"
  value = {
    storage       = "S3 (s3://${aws_s3_bucket.databricks_data.id})"
    region        = "us-east-1"
    catalog       = var.catalog_name
    iam_profile   = aws_iam_instance_profile.databricks_s3.name
  }
}
