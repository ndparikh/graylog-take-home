resource "null_resource" "create_ns" {
  depends_on = [aws_eks_node_group.backend, aws_eks_cluster.be]
  triggers = {
    always_run = timestamp()
  }
  provisioner "local-exec" {
    command = <<-EOT
           set -e
           aws eks update-kubeconfig --name ${var.app_name}  --region ${var.region} --kubeconfig ./kube-config
           export KUBECONFIG=./kube-config
           kubectl apply -f templates/namespaces.yml
      EOT
  }
}
resource "helm_release" "alb_ingress_controller" {
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be, null_resource.create_ns]
  name             = "alb-ingress-controller"
  chart            = "../helm/aws-load-balancer-controller"
  namespace        = "devops"
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
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be, null_resource.create_ns]
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
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be, null_resource.create_ns]
  name             = "merge-ingress"
  chart            = "../helm/merge-ingress"
  namespace        = "devops"
  create_namespace = true
  atomic           = false
  cleanup_on_fail  = true

  set {
    name  = "acm"
    value = var.acm
  }
}

resource "helm_release" "metrics_server" {
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be, null_resource.create_ns]
  name             = "metrics-server"
  chart            = "../helm/metrics-server"
  namespace        = "devops"
  create_namespace = true
  atomic           = false
  cleanup_on_fail  = true

}

resource "helm_release" "cluster_autoscaler" {
  depends_on       = [aws_eks_node_group.backend, aws_eks_cluster.be, null_resource.create_ns]
  name             = "cluster-autoscaler"
  chart            = "../helm/cluster-autoscaler"
  namespace        = "devops"
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
  depends_on       = [null_resource.docker_push, null_resource.create_ns, aws_eks_node_group.backend, aws_eks_cluster.be, helm_release.merge-ingress, helm_release.cluster_autoscaler, helm_release.alb_ingress_controller, helm_release.external-dns]
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
    value = var.app_version
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
