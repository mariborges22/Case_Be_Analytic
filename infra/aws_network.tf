# VPC para Databricks
resource "aws_vpc" "databricks" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "databricks-vpc"
  }
}

# Subnet
resource "aws_subnet" "databricks" {
  vpc_id                  = aws_vpc.databricks.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "databricks-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "databricks" {
  vpc_id = aws_vpc.databricks.id

  tags = {
    Name = "databricks-igw"
  }
}

# Route Table
resource "aws_route_table" "databricks" {
  vpc_id = aws_vpc.databricks.id

  route {
    cidr_block      = "0.0.0.0/0"
    gateway_id      = aws_internet_gateway.databricks.id
  }

  tags = {
    Name = "databricks-rt"
  }
}

# Associate subnet with route table
resource "aws_route_table_association" "databricks" {
  subnet_id      = aws_subnet.databricks.id
  route_table_id = aws_route_table.databricks.id
}

# Security Group
resource "aws_security_group" "databricks" {
  name   = "databricks-sg"
  vpc_id = aws_vpc.databricks.id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "databricks-sg"
  }
}

# Adicione um bloco separado para permitir tráfego entre instâncias da mesma SG
resource "aws_security_group_rule" "databricks_self" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 65535
  protocol                 = "tcp"
  security_group_id        = aws_security_group.databricks.id
  source_security_group_id = aws_security_group.databricks.id
}

# Instance Profile para IAM Role
resource "aws_iam_instance_profile" "databricks_s3_access" {
  name = "databricks-instance-profile"
  role = aws_iam_role.databricks_s3_access.name
}
