# S3 Bucket para dados
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_versioning" "databricks_data" {
  bucket = aws_s3_bucket.databricks_data.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "databricks_data" {
  bucket = "databricks-mco-lakehouse-useast2"  # Nome novo para us-east-2
  
  tags = {
    Environment = "production"
    Purpose     = "databricks-lakehouse"
    ManagedBy   = "terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

# Bucket Policy para permitir acesso explícito do Role (Resolve 403 no Unity Catalog)
resource "aws_s3_bucket_policy" "databricks_data_policy" {
  bucket = aws_s3_bucket.databricks_data.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.databricks_s3_access.arn
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetLifecycleConfiguration"
        ]
        Resource = [
          aws_s3_bucket.databricks_data.arn,
          "${aws_s3_bucket.databricks_data.arn}/*"
        ]
      }
    ]
  })
}

# Versionamento do bucket


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
  name = "case_be_analytic"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::414351767826:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.databricks_account_id
          }
        }
      },
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          ArnEquals = {
            "aws:PrincipalArn" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/databricks-s3-access-role"
          }
        }
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
          "s3:GetBucketLocation",
          "s3:GetLifecycleConfiguration",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketPolicyStatus"
        ]
        Resource = [
          aws_s3_bucket.databricks_data.arn,
          "${aws_s3_bucket.databricks_data.arn}/*"
        ]
      }
    ]
  })
}

# Registrar Instance Profile no Databricks - REMOVIDO (Uso de Unity Catalog)
# resource "databricks_instance_profile" "s3_access" {
#   instance_profile_arn = aws_iam_instance_profile.databricks_s3.arn
#   skip_validation      = true
# }