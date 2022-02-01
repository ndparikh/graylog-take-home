data "aws_caller_identity" "current" {}

# Get VPC id
data "aws_vpc" "selected" {
  depends_on = [aws_vpc.ops]
  tags = {
    Name = "*${var.app_name}*"
  }
}

data "aws_subnet_ids" "subnets" {
  vpc_id = data.aws_vpc.selected.id

  tags = {
    "kubernetes.io/role/internal-elb" = "*1*"
  }
}

data "aws_caller_identity" "current_aws_account" {}
data "aws_region" "current" {}

data "aws_ssm_parameter" "eks_workers" {
  name = "/aws/service/eks/optimized-ami/${var.cluster_version}/amazon-linux-2/recommended/image_id"
}
