terraform {
  required_version = ">=1.9.0"

  backend "s3" {
    bucket = "example-bucket" # Replace this with the name of a bucket you created
    key    = "terraform.tfstate"
    region = "ap-southeast-2"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.80.0"
    }
  }
}
