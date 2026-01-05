locals {
    ubuntu_ami = data.aws_ami.ubuntu.id
    cluster_name = "kubernetes"
}


data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]

filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
}

# 1. Create the VPC
resource "aws_vpc" "k8s_vpc" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true

    tags = {
        Name = "k8s-vpc"
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }
    }

# 2. Create the Public Subnet
resource "aws_subnet" "k8s_public_subnet" {
    vpc_id                  = aws_vpc.k8s_vpc.id
    cidr_block              = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone       = "us-east-1a" # Change to your region's zone

    tags = {
        Name                                          = "k8s-public-subnet"
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
        "kubernetes.io/role/elb"                      = "1" # Required for Public LBs
    }
}

    # 3. Internet Gateway & Route Table (To allow traffic in/out)
resource "aws_internet_gateway" "k8s_igw" {
    vpc_id = aws_vpc.k8s_vpc.id
}

resource "aws_route_table" "k8s_public_rt" {
    vpc_id = aws_vpc.k8s_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.k8s_igw.id
    }
}

resource "aws_route_table_association" "k8s_public_assoc" {
    subnet_id      = aws_subnet.k8s_public_subnet.id
    route_table_id = aws_route_table.k8s_public_rt.id
}

resource "aws_instance" "control_plane" {
    ami = local.ubuntu_ami
    instance_type = "t3.medium"
    key_name = var.key_name
    subnet_id = aws_subnet.k8s_public_subnet.id
    user_data = file("${path.module}/k8s-node.sh")


    root_block_device {
    volume_size = 20
    volume_type = "gp3"
    }


    vpc_security_group_ids = [
    aws_security_group.k8s_cluster_sg.id,
    aws_security_group.control_plane_kubectl_sg.id
    ]


    tags = {
        Name = "k8s-control-plane"
    }
}


resource "aws_instance" "worker" {
    count = 2
    ami = local.ubuntu_ami
    instance_type = "t3.small"
    key_name = var.key_name
    subnet_id = aws_subnet.k8s_public_subnet.id
    user_data = file("${path.module}/k8s-node.sh")


    root_block_device {
    volume_size = 20
    volume_type = "gp3"
    }


    vpc_security_group_ids = [
    aws_security_group.k8s_cluster_sg.id,
    aws_security_group.worker_nodes_sg.id
    ]


    tags = {
        Name = "k8s-worker-${count.index + 1}"
    }
}