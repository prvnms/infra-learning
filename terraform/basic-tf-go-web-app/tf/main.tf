provider "aws" {
  region = "us-east-1" 
}

# Security Group to allow SSH and HTTP (8080)
resource "aws_security_group" "go_server_sg" {
  name        = "go-server-sg"
  description = "Allow SSH and Go server access"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Go server"
    from_port   = 8080
    to_port     = 8080
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

# EC2 instance
resource "aws_instance" "go_server" {
  ami                         = "ami-0c2b8ca1dad447f8a" 
  instance_type               = "t2.micro"
  key_name                    = "go-ec2-ssh-key"  
  vpc_security_group_ids      = [aws_security_group.go_server_sg.id]
  associate_public_ip_address = true

  # user_data = <<-EOF
  #             #!/bin/bash
  #             yum update -y
  #             yum install -y git golang
  #             # Assuming your Go server code is hosted on GitHub
  #             git clone https://github.com/yourusername/your-go-server.git /home/ec2-user/go-server
  #             cd /home/ec2-user/go-server
  #             go build -o server
  #             nohup ./server > server.log 2>&1 &
  #             EOF

  tags = {  
    Name = "go-web-server"
  }
}


