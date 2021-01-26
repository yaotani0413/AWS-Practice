# variable "access_key" {}
# variable "secret_key" {}
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
  default = "key-yao2"
}

variable "public_key_path" {
  default = "~/key-yao2.pem"
}

variable "instance_type" {
  default = "t2.micro"
}