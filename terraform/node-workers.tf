data "aws_launch_template" "backend" {
  name = aws_launch_template.backend.name

  depends_on = [aws_launch_template.backend]
}

data "template_file" "backend" {
  template = file("userdata/backend.sh")

  vars = {
    cluster_endpoint = aws_eks_cluster.be.endpoint
    b64_cluster_ca   = aws_eks_cluster.be.certificate_authority.0.data
    cluster_name     = var.app_name
    vpc_cidr         = data.aws_vpc.selected.cidr_block
  }
}

resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "kp" {
  key_name   = var.app_name
  public_key = tls_private_key.pk.public_key_openssh

  #  provisioner "local-exec" { # Create "myKey.pem" to your computer!!
  #   command = "echo '${tls_private_key.pk.private_key_pem}' > ./myKey.pem"
  # }
}
resource "aws_launch_template" "backend" {
  image_id               = data.aws_ssm_parameter.eks_workers.value
  instance_type          = "c5.large"
  name                   = var.app_name
  vpc_security_group_ids = [aws_security_group.workers_node.id]
  update_default_version = true

  key_name = aws_key_pair.kp.key_name

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  tag_specifications {
    resource_type = "instance"

    tags = map(
      "Name", "${var.app_name}-worker",
      "kubernetes.io/cluster/${var.app_name}", "owned",
    )
  }

  user_data = base64encode(data.template_file.backend.rendered)
  lifecycle {
    ignore_changes = [vpc_security_group_ids, tags, tag_specifications]
  }
}

resource "aws_eks_node_group" "backend" {
  cluster_name           = aws_eks_cluster.be.name
  node_group_name_prefix = var.app_name
  node_role_arn          = aws_iam_role.eks_node.arn
  subnet_ids             = data.aws_subnet_ids.subnets.ids
  launch_template {
    id      = data.aws_launch_template.backend.id
    version = data.aws_launch_template.backend.latest_version
  }
  scaling_config {
    desired_size = 1
    max_size     = 10
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node-AmazonEC2ContainerRegistryReadOnly,
  ]

  tags = map(
    "Name", "var.app_name",
    "kubernetes.io/cluster/var.app_name", "owned",
  )


  lifecycle {
    ignore_changes = [scaling_config, tags, launch_template]
  }

}
