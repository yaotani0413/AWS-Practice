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
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1a"

  cidr_block        = "10.1.1.0/24"

  tags = {
    Name = "public_subnet1"
  }
}

resource "aws_subnet" "public_subnet2" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1c"

  cidr_block        = "10.1.2.0/24"

  tags = {
    Name = "public_subnet2"
  }
}

resource "aws_subnet" "private_subnet1" {
  vpc_id = "${aws_vpc.main.id}"

  availability_zone = "ap-northeast-1a"

  cidr_block        = "10.1.100.0/24"

  tags = {
    Name = "private_subnet1"
  }
}

resource "aws_subnet" "private_subnet2" {
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

# ====================
# Route Table
# ====================

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
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.main_RT.id
}

resource "aws_route_table_association" "public_subnet2" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.main_RT.id
}

# ====================
# AMI
# ====================

# 最新版のAmazonLinux2のAMI情報
data aws_ssm_parameter amzn2_ami {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# ====================
# EC2 インスタンス
# ====================

resource "aws_instance" "TeraTestVM1" {
  # count                   = 1
  ami = data.aws_ssm_parameter.amzn2_ami.value
  vpc_security_group_ids = [aws_security_group.TeraTest-SG.id]
  subnet_id              = aws_subnet.public_subnet1.id
  instance_type           = var.instance_type
  disable_api_termination = false
  key_name                = var.key_name
  tags = {
    Name = "TeraTest1"
  }
}

resource "aws_instance" "TeraTestVM2" {
  # count                   = 1
  ami = data.aws_ssm_parameter.amzn2_ami.value
  vpc_security_group_ids = [aws_security_group.TeraTest-SG.id]
  subnet_id              = aws_subnet.public_subnet2.id
  instance_type           = var.instance_type
  disable_api_termination = false
  key_name                = var.key_name
  tags = {
    Name = "TeraTest2"
  }
}

# ====================
# Elastic IP 
# ====================
resource "aws_eip" "TeraTest-EIP1" {
  instance = aws_instance.TeraTestVM1.id
  vpc      = true

  tags = {
    Name = "TeraTest-EIP1"
  }
}

resource "aws_eip" "TeraTest-EIP2" {
  instance = aws_instance.TeraTestVM2.id
  vpc      = true

  tags = {
    Name = "TeraTest-EIP2"
  }
}

# ====================
# Key Pair
# ====================

# resource "aws_key_pair" "auth" {
#   key_name   = var.key_name
#   public_key = var.public_key_path
# }

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

resource "aws_security_group" "TeraTestforMySQL" {
  vpc_id = aws_vpc.main.id
  name   = "TeraTestforMySQL"

  tags = {
    Name = "TeraTestforMySQL"
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

### インバウンドルール(httpアクセス用)
resource "aws_security_group_rule" "in_http" {
  security_group_id = aws_security_group.TeraTest-SG.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
}

### インバウンドルール(httpsアクセス用)
resource "aws_security_group_rule" "in_https" {
  security_group_id = aws_security_group.TeraTest-SG.id
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
}

### インバウンドルール(DB接続用)
resource "aws_security_group_rule" "db" {
  security_group_id = aws_security_group.TeraTestforMySQL.id
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  cidr_blocks = [aws_vpc.main.cidr_block]
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

# ====================
# Route53
# ====================

resource "aws_route53_zone" "myzone" {
   name = "yao3dr.net"
}

resource "aws_route53_record" "terra" {
  zone_id = aws_route53_zone.myzone.zone_id
  name    = "terra"
  type    = "A"
  ttl     = "300"
  records = [aws_eip.TeraTest-EIP1.public_ip]
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.myzone.zone_id
  name    = "terraalb"
  type    = "A"

  alias {
    name                   = aws_lb.TerraALB.dns_name
    zone_id                = aws_lb.TerraALB.zone_id
    evaluate_target_health = true
  }
}

# ====================
# RDS
# ====================

# サブネットグループ
resource "aws_db_subnet_group" "TerraDB-SG" {
  name       = "terradb_sg"
  subnet_ids = [aws_subnet.private_subnet1.id, aws_subnet.private_subnet2.id]

  tags = {
    Name = "terradb_sg"
  }
}

# インスタンス
resource "aws_db_instance" "TerraDB" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7.31"
  instance_class       = "db.t2.micro"
  name                 = "TerraDB"
  username             = "yao"
  password             = "testtest"
  # parameter_group_name = "default.mysql5.7.31"
  vpc_security_group_ids  = [aws_security_group.TeraTestforMySQL.id]
  db_subnet_group_name = aws_db_subnet_group.TerraDB-SG.name
  skip_final_snapshot = true
}

# パラメーター
# resource "aws_db_parameter_group" "default" {
#   name   = "rds-pg"
#   family = "mysql5.6"

#   parameter {
#     name  = "character_set_server"
#     value = "utf8"
#   }

#   parameter {
#     name  = "character_set_client"
#     value = "utf8"
#   }
# }

# ====================
# ALB
# ====================

# ALB
resource "aws_lb" "TerraALB" {
  name                       = "TerraALB"
  load_balancer_type         = "application"
  internal                   = false
  idle_timeout               = 60
  security_groups    = [aws_security_group.TeraTest-SG.id]
  subnets            = [aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id]
  # enable_deletion_protection = true

  tags = {
    Name = "TerraALB"
  }
}

# ターゲットグループ
resource "aws_lb_target_group" "TerraTG" {
  name                 = "TerraTG"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = aws_vpc.main.id

  health_check {
    path                = "/"
    port                = 80
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    matcher             = 200
  }
}

resource "aws_lb_target_group_attachment" "TG-attach1" {
  target_group_arn = aws_lb_target_group.TerraTG.arn
  target_id        = aws_instance.TeraTestVM1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "TG-attach2" {
  target_group_arn = aws_lb_target_group.TerraTG.arn
  target_id        = aws_instance.TeraTestVM2.id
  port             = 80
}

# リスナー
resource "aws_lb_listener" "front_end1" {
  load_balancer_arn = aws_lb.TerraALB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TerraTG.arn
  }
}

resource "aws_lb_listener" "front_end2" {
  load_balancer_arn = aws_lb.TerraALB.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:ap-northeast-1:529323424893:certificate/85c81d1d-c7a8-474b-b62b-ac2d270fcc21"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.TerraTG.arn
  }
}

resource "aws_lb_listener_certificate" "example" {
  listener_arn    = aws_lb_listener.front_end2.arn
  certificate_arn = aws_acm_certificate.cert.arn
}

# ====================
# ACM
# ====================

resource "aws_acm_certificate" "cert" {
  domain_name       = "*.yao3dr.net"
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

