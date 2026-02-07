# S3 Bucket para dados
resource "aws_s3_bucket" "databricks_data" {
  bucket = "databricks-mco-lakehouse"
  
  tags = {
    Environment = "production"
    Purpose     = "databricks-lakehouse"
    ManagedBy   = "terraform"
  }
}

# Versionamento do bucket
resource "aws_s3_bucket_versioning" "databricks_data" {
  bucket = aws_s3_bucket.databricks_data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

# Criptografia
resource "aws_s3_bucket_server_side_encryption_configuration" "databricks_data" {
  bucket = aws_s3_bucket.databricks_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Bloquear acesso público
resource "aws_s3_bucket_public_access_block" "databricks_data" {
  bucket = aws_s3_bucket.databricks_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role para Databricks acessar S3
resource "aws_iam_role" "databricks_s3_access" {
  name = "databricks-s3-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name      = "databricks-s3-access"
    ManagedBy = "terraform"
  }
}

# Policy para acesso S3
resource "aws_iam_role_policy" "databricks_s3_policy" {
  name = "databricks-s3-access-policy"
  role = aws_iam_role.databricks_s3_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.databricks_data.arn,
          "${aws_s3_bucket.databricks_data.arn}/*"
        ]
      }
    ]
  })
}

# Instance Profile para anexar aos clusters
resource "aws_iam_instance_profile" "databricks_s3" {
  name = "databricks-s3-instance-profile"
  role = aws_iam_role.databricks_s3_access.name
}

# Outputs úteis
output "s3_bucket_name" {
  value       = aws_s3_bucket.databricks_data.id
  description = "Nome do bucket S3"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.databricks_data.arn
  description = "ARN do bucket S3"
}

output "instance_profile_arn" {
  value       = aws_iam_instance_profile.databricks_s3.arn
  description = "ARN do instance profile"
}