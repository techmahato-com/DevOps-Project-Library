terraform {
  backend "s3" {
    bucket         = "your-terraform-state-bucket-name"
    key            = "prod/terraform.tfstate"
    region         = "ap-south-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
