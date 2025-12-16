# Uncomment and configure for remote state management
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state-bucket"
#     key            = "vpc/terraform.tfstate"
#     region         = "us-east-1"
#     dynamodb_table = "terraform-state-lock"
#     encrypt        = true
#   }
# }
