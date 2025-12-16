terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# ------------------------
# Networking (Default VPC)
# ------------------------

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


# Security Groups
# ALB SG
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = data.aws_vpc.default.id

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
}

# EC2-Web SG (ALB → EC2)
resource "aws_security_group" "ec2_web_sg" {
  name   = "ec2-web-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 SSH SG 
resource "aws_security_group" "ec2_ssh_sg" {
  name   = "ec2-ssh-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# EC2 Instances 
resource "aws_instance" "go_ec2" {
  count         = 2
  ami           = "ami-0c02fb55956c7d316" 
  instance_type = "t2.micro"
  key_name      = "go-ec2-ssh-key"

  vpc_security_group_ids = [
    aws_security_group.ec2_web_sg.id,
    aws_security_group.ec2_ssh_sg.id
  ]

  tags = {
    Name = "go-ws-${count.index + 1}"
  }
}


# Target Group
resource "aws_lb_target_group" "go_tg" {
  name     = "go-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
    port = "traffic-port"
  }
}

# Attach EC2s to Target Group
resource "aws_lb_target_group_attachment" "attach" {
  count            = 2
  target_group_arn = aws_lb_target_group.go_tg.arn
  target_id        = aws_instance.go_ec2[count.index].id
  port             = 8080
}


# ALB
resource "aws_lb" "go_alb" {
  name               = "go-alb"
  load_balancer_type = "application"
  subnets            = data.aws_subnets.default.ids
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.go_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.go_tg.arn
  }
}
