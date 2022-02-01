variable "region" {
  description = "aws region to deploy resources"
  default     = "us-east-1"
}

variable "cluster_version" {
  default = "1.21"
}

#  VPC cidr
variable "vpc_cidr" {
  default = "10.16.0.0/23"
}

# app_name
variable "app_name" {
  default = "graylog-gk"
}

#Internal Subnets CIDR
variable "internal_subnets_cidrs" {
  default = "10.16.1.0/25,10.16.1.128/25"
}

# External Subnets CIDR
variable "external_subnets_cidrs" {
  default = "10.16.0.0/25,10.16.0.128/25"
}

variable "internal_subnet_tags" {
  description = "Additional tags for all internal facings subnets"

  default = {
    "purpose"                          = "used for all internal facing apps"
    "supported_app_types"              = "internal"
    "kubernetes.io/cluster/graylog-gk" = "shared"
    "kubernetes.io/role/internal-elb"  = "1"
  }
}

variable "external_subnet_tags" {
  description = "Additional tags for the external subnets"

  default = {
    "purpose"                          = "used for all external facing apps"
    "supported_app_types"              = "all external facing load balancers"
    "kubernetes.io/cluster/graylog-gk" = "shared"
    "kubernetes.io/role/elb"           = "1"
  }
}
