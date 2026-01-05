resource "aws_iam_role" "k8s_nodes" {
    name = "k8s-selfmanaged-nodes"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
        Effect = "Allow"
        Principal = {
            Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        }]
    })
}

resource "aws_iam_role_policy_attachment" "ccm_policy" {
    role       = aws_iam_role.k8s_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "elb_full_access" {
    role       = aws_iam_role.k8s_nodes.name
    policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
}

resource "aws_iam_instance_profile" "k8s_nodes" {
    name = "k8s-nodes-instance-profile"
    role = aws_iam_role.k8s_nodes.name
}
