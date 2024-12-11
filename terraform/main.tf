provider "aws" {
  region = "ap-southeast-2"

  assume_role {
    role_arn = "arn:aws:iam:123456789012:role/my-terraform-role" # This should be replaced with an IAM role in your AWS account with sufficient permission
  }
}
