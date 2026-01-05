# 1. Create the IAM Role
resource "aws_iam_role" "ebs_csi_role" {
  name = "ebs-csi-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# 2. Attach the AWS Managed Policy for EBS CSI
resource "aws_iam_role_policy_attachment" "ebs_csi_attach" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# 3. Create the Instance Profile
resource "aws_iam_instance_profile" "ebs_csi_profile" {
  name = "ebs-csi-instance-profile"
  role = aws_iam_role.ebs_csi_role.name
}

