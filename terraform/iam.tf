# This policy allows access to vpc flow logs to cloudwatch group.
resource "aws_iam_policy" "vpc_flow_logs" {
  name        = "${var.app_name}-vpc-flow-log-policy"
  path        = "/"
  description = "This policy allows access to vpc flow logs to cloudwatch group."

  policy = file("templates/vpc_policy.json")
}

# Create a role which vpc flow logs will assume.
resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.app_name}-vpc-flow-logs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Attach the policy to vpc flow logs role.
resource "aws_iam_policy_attachment" "vpc_flow_logs" {
  name       = "vpc-flow-logs-attach-policy"
  roles      = [aws_iam_role.vpc_flow_logs.name]
  policy_arn = aws_iam_policy.vpc_flow_logs.arn
}

########################################################################################
# Setup IAM role & instance profile for worker nodes

resource "aws_iam_role" "eks_node" {
  name = var.app_name

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "eks_workers_policy" {
  name        = "eks-workers-policy-${var.app_name}"
  path        = "/"
  description = "This policy allows k8s external dns, aws-alb-controller and merge ingress controller to create ALB and routing."

  policy = file("templates/eks-workers-policy.json")
}

# Attach the policy to pods-aws-alb-controller-role.
resource "aws_iam_policy_attachment" "eks_workers_policy" {
  name       = "eks-workers"
  roles      = [aws_iam_role.eks_node.name]
  policy_arn = aws_iam_policy.eks_workers_policy.arn
}

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_role_policy_attachment" "eks_node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node.name
}

resource "aws_iam_instance_profile" "node" {
  name = "${var.app_name}-workers"
  role = aws_iam_role.eks_node.name
}

resource "aws_security_group" "workers_node" {
  name        = "${var.app_name}-workers"
  description = "Security group for all nodes in the cluster"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = map(
    "Name", "var.app_name",
    "kubernetes.io/cluster/${var.app_name}", "owned"
  )
}
