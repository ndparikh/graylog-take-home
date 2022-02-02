provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.16.0"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.be.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.be.certificate_authority.0.data)
    exec {
      api_version = "client.authentication.k8s.io/v1alpha1"
      args        = ["eks", "get-token", "--cluster-name", aws_eks_cluster.be.name]
      command     = "aws"
    }
  }
}
