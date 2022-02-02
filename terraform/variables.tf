################Start Configuration############################

variable "region" {
  description = "aws region to deploy resources"
  default     = "us-east-1"
}

variable "acm" {
  description = "AWS Certificate manager certificate arn"
#  default     = ""

}

variable "route53_domain" {
  description = "route53 domain where the dns record for the k8s will be created"
#  default     = "ZP2XDHTRBXZW"
}

variable "app_dns_name" {
  description = "route53 dns record name. graylog.allcloudthings.com. Where the domain name depends on route53_domain above"
#  default     = "graylog-test-gk.allcloudthings.com"
}

variable "app_version" {
  description = "Docker image version"
  default     = "1.0.0"
}
################End Configuration############################
variable "tags" {
  description = "A map of tags to add to all resources"

  default = {
    "dept"  = "ops"
    "owner" = "devops"
  }
}

variable "internal_subnet_tags" {
  description = "Additional tags for all internal facings subnets"

  default = {
    "purpose"                         = "used for all internal facing apps"
    "supported_app_types"             = "internal"
    "kubernetes.io/cluster/graylog"   = "shared"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
variable "cluster_version" {
  default = "1.21"
}
# app_name
variable "app_name" {
  default = "graylog"
}
#  VPC cidr
variable "vpc_cidr" {
  default = "10.16.0.0/23"
}

# External Subnets CIDR
variable "external_subnets_cidrs" {
  default = "10.16.0.0/25,10.16.0.128/25"
}

#Internal Subnets CIDR
variable "internal_subnets_cidrs" {
  default = "10.16.1.0/25,10.16.1.128/25"
}


variable "external_subnet_tags" {
  description = "Additional tags for the external subnets"

  default = {
    "purpose"                       = "used for all external facing apps"
    "supported_app_types"           = "all external facing load balancers"
    "kubernetes.io/cluster/graylog" = "shared"
    "kubernetes.io/role/elb"        = "1"
  }
}

