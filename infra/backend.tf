terraform {
  backend "s3" {
    bucket         = "terraform-state-case-be-analytic"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
