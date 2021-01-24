# ====================
# Provider
# ====================

provider "aws" {
  region = "ap-northeast-1"
  profile = "yao-test"
}

# ====================
# VPC
# ====================

resource "aws_vpc" "main" {
  cidr_block = "10.1.0.0/16"

  tags = {
    Name = "TeraTest"
  }
}

# ====================
# Subnet 
# ====================

resource "aws_subnet" "public_subnet1" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1a"

  cidr_block        = "10.1.1.0/24"

  tags = {
    Name = "public_subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1c"

  cidr_block        = "10.1.2.0/24"

  tags = {
    Name = "public_subnet2"
  }
}

resource "aws_subnet" "private_subnet1" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1a"

  cidr_block        = "10.1.100.0/24"

  tags = {
    Name = "private_subnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
  # 先程作成したVPCを参照し、そのVPC内にSubnetを立てる
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1c"

  cidr_block        = "10.1.101.0/24"

  tags = {
    Name = "private_subnet2"
  }
}
# ====================
# Internet Gateway 
# ====================

resource "aws_internet_gateway" "main_GW" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main_GW"
  }
}

#### Route Table ####
# https://www.terraform.io/docs/providers/aws/r/route_table.html
resource "aws_route_table" "main_RT" {
  vpc_id = "${aws_vpc.main.id}"

  tags = {
    Name = "main_RT"
  }
}

# ====================
# Route 
# ====================

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${aws_route_table.main_RT.id}"
  gateway_id             = "${aws_internet_gateway.main_GW.id}"
}

# ====================
# Association 
# ====================

resource "aws_route_table_association" "public_subnet1" {
  subnet_id      = "${aws_subnet.public_subnet1.id}"
  route_table_id = "${aws_route_table.main_RT.id}"
}

resource "aws_route_table_association" "public_subnet2" {
  subnet_id      = "${aws_subnet.public_subnet2.id}"
  route_table_id = "${aws_route_table.main_RT.id}"
}

# ====================
# AMI
# ====================

# 最新版のAmazonLinux2のAMI情報
data "aws_ami" "example" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "block-device-mapping.volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# ====================
# EC2 インスタンス
# ====================

resource "aws_instance" "TeraTestVM1" {
  ami                    = data.aws_ami.example.image_id
  vpc_security_group_ids = [aws_security_group.TeraTest-SG.id]
  subnet_id              = aws_subnet.public_subnet1.id
  key_name               = aws_key_pair.deployer.id
  instance_type          = "t2.micro"

  tags = {
    Name = "TeraTest1"
  }
}

# ====================
# Elastic IP 
# ====================
resource "aws_eip" "TeraTest-EIP" {
  instance = aws_instance.TeraTestVM1.id
  vpc      = true
}

# ====================
# Key Pair
# ====================

resource "aws_key_pair" "deployer" {
  key_name   = "key-yao"
  public_key = ""
}

# ====================
# Security Group
# ====================

resource "aws_security_group" "TeraTest-SG" {
  vpc_id = aws_vpc.main.id
  name   = "TeraTest-SG"

  tags = {
    Name = "TeraTest-SG"
  }
}

### インバウンドルール(ssh接続用)
resource "aws_security_group_rule" "in_ssh" {
  security_group_id = aws_security_group.TeraTest-SG.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
}

### インバウンドルール(pingコマンド用)
resource "aws_security_group_rule" "in_icmp" {
  security_group_id = aws_security_group.TeraTest-SG.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
}

### アウトバウンドルール(全開放)
resource "aws_security_group_rule" "out_all" {
  security_group_id = aws_security_group.TeraTest-SG.id
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
}