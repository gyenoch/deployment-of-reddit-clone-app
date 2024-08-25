terraform {
  backend "s3" {
    bucket         = "gyenoch-reddit-clone" # Replace with your actual S3 bucket name
    key            = "EKS/terraform.tfstate"
    dynamodb_table = "terraform-state-lock"
    region         = "us-east-1"
  }
}
