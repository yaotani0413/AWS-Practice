variable "access_key" {}
variable "secret_key" {}
variable "key_name" {}
variable "public_key_path" {}
variable "region" {
  default = "ap-northeast-1"
}

# ====================
# EC2 インスタンス
# ====================

variable "ami" {
  default = "ami-0f53b51ee1388fd0b" ## AmazonLinux2
}

variable "key_name" {
  default = "key-yao"
}

variable "public_key_path" {
  default = "~/.ssh/terraform.pub"
}

variable "instance_type" {
  default = "a1.2xlarge"
}