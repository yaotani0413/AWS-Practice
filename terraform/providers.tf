# ====================
# Provider
# ====================

provider "aws" {
  region = "ap-northeast-1"
  profile = "yao-test"
}

terraform {
  required_version = "0.14.5"
  backend "s3" {
    bucket  = "terrabucket-yao"
    key     = "terraform.tfstate"
    region  = "ap-northeast-1"
    profile = "yao-test"
  }
}