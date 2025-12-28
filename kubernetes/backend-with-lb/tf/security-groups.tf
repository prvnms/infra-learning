resource "aws_security_group" "k8s_cluster_sg" {
    name        = "k8s-cluster-sg"
    vpc_id = aws_vpc.k8s_vpc.id
    description = "K8s node communication"


    ingress {
        description = "API server"
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        self        = true
    }


    ingress {
        description = "kubelet"
        from_port   = 10250
        to_port     = 10250
        protocol    = "tcp"
        self        = true
    }


    ingress {
        description = "etcd"
        from_port   = 2379
        to_port     = 2380
        protocol    = "tcp"
        self        = true
    }


    ingress {
        description = "NodePort from ELB"
        from_port   = 30000
        to_port     = 32767
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }


    ingress {
        description = "SSH internal"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        self        = true
    }

    ingress {
        description = "SSH local to vm"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }



    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_security_group" "control_plane_kubectl_sg" {
    name = "control-plane-kubectl-sg"
    vpc_id = aws_vpc.k8s_vpc.id


    ingress {
        description = "kubectl access"
        from_port   = 6443
        to_port     = 6443
        protocol    = "tcp"
        cidr_blocks = ["${var.my_ip}/32"]
    }

}

resource "aws_security_group" "worker_nodes_sg" {
    name = "worker_nodes_sg"
    vpc_id = aws_vpc.k8s_vpc.id

    ingress {
        description = "pod access port open to access appp"
        from_port   = 30494
        to_port     = 30494
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

}
