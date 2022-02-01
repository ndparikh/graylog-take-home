resource "helm_release" "alb_ingress_controller" {
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be]
  name             = "alb-ingress-controller"
  chart            = "../helm/aws-load-balancer-controller"
  namespace        = "alb-ingress-controller"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true

  set {
    name  = "clusterName"
    value = aws_eks_cluster.be.name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcID"
    value = aws_vpc.ops.id
  }
}

resource "helm_release" "external-dns" {
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be]
  name             = "external-dns"
  chart            = "../helm/external-dns"
  namespace        = "devops"
  create_namespace = true
  atomic           = true
  cleanup_on_fail  = true

  set {
    name  = "route53_domain"
    value = var.route53_domain
  }

  set {
    name  = "cluster_name"
    value = aws_eks_cluster.be.name
  }
}

resource "helm_release" "merge-ingress" {
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be]
  name             = "merge-ingress"
  chart            = "../helm/merge-ingress"
  namespace        = "merge-ingress"
  create_namespace = true
  atomic           = false
  cleanup_on_fail  = true

  set {
    name  = "acm"
    value = var.acm
  }
}

resource "helm_release" "metrics_server" {
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be]
  name             = "metrics-server"
  chart            = "../helm/metrics-server"
  namespace        = "devops"
  create_namespace = true
  atomic           = false
  cleanup_on_fail  = true

}

resource "helm_release" "cluster_autoscaler" {
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be]
  name             = "cluster-autoscaler"
  chart            = "../helm/cluster-autoscaler"
  namespace        = "cluster-autoscaler"
  create_namespace = true
  atomic           = false
  cleanup_on_fail  = true

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "clusterName"
    value = aws_eks_cluster.be.name
  }
}


resource "helm_release" "graylog" {
  depends_on       = [null_resource.docker_push, aws_eks_node_group.backend, aws_eks_cluster.be]
  name             = "graylog"
  chart            = "../helm/graylog"
  namespace        = "graylog"
  create_namespace = true
  atomic           = false
  cleanup_on_fail  = true

  set {
    name  = "route53_dns"
    value = var.app_dns_name
  }
  set {
    name  = "image.repository"
    value = aws_ecr_repository.my_app.repository_url
  }

  set {
    name  = "image.tag"
    value = "1.0.0"
  }

  set {
    name  = "image.pullPolicy"
    value = "Always"
  }

  set {
    name  = "ingress.enabled"
    value = true
  }
}
