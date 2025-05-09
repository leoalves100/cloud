# ------------------------------------------------------------------------------
# LOCALS
# ------------------------------------------------------------------------------

locals {
  name           = "web-server"
  subnets_chunck = element(chunklist(data.aws_subnets.default.ids, 3), 1)
}

# ------------------------------------------------------------------------------
# Data Sources
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets
# ------------------------------------------------------------------------------

data "aws_ami" "amazon_linux" {
  owners = ["amazon"]

  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.7*"]
  }

  filter {
    name   = "architecture"
    values = ["arm64"]
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ------------------------------------------------------------------------------
# EC2 Instance
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance
# ------------------------------------------------------------------------------

resource "aws_security_group" "web_server" {
  name        = "${local.name}-httpd"
  description = "Allow traffic to EC2 instance"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.web_server_alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-httpd"
  }
}

resource "aws_instance" "web_server" {
  count         = 2
  ami           = data.aws_ami.amazon_linux.id # ami-0bc72bd3b8ba0b59d
  instance_type = "t4g.micro"
  # Cheaper than t3a.micro and uses arm
  # Ref: https://instances.vantage.sh/?filter=t3a.micro|t4g.micro&compare_on=true&selected=t3a.micro,t4g.micro
  vpc_security_group_ids = [aws_security_group.web_server.id]

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>Hello World from $(hostname -f)<h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${local.name}-${count.index}"
  }
}

# ------------------------------------------------------------------------------
# Load Balancer
# Ref: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
# ------------------------------------------------------------------------------

resource "aws_security_group" "web_server_alb" {
  name        = "${local.name}-alb"
  description = "Allow traffic to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = local.name
  }
}

resource "aws_lb" "web_server" {
  name               = local.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_server_alb.id]
  subnets            = [for subnet in local.subnets_chunck : subnet]
}

resource "aws_lb_listener" "web_server" {
  load_balancer_arn = aws_lb.web_server.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server.arn
  }
}

resource "aws_lb_target_group" "web_server" {
  name        = local.name
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_lb_target_group_attachment" "web_server" {
  for_each = {
    for k, v in aws_instance.web_server :
    k => v
  }

  target_group_arn = aws_lb_target_group.web_server.arn
  target_id        = each.value.id
  port             = 80
}
