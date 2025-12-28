locals {
    ubuntu_ami = data.aws_ami.ubuntu.id
}


data "aws_ami" "ubuntu" {
    most_recent = true
    owners = ["099720109477"]

filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
}


resource "aws_instance" "control_plane" {
    ami = local.ubuntu_ami
    instance_type = "t3.medium"
    key_name = var.key_name

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