# Get list of availability zones for the region
data "aws_availability_zones" "available_zones" {
  state = "available"
#excluding us-east-1e for now since no eks capacity
exclude_names = ["us-east-1e"]
}

# Get same number of random az's as internal subnet cidr blocks
resource "random_shuffle" "az" {
  input = data.aws_availability_zones.available_zones.names
  result_count = length(
    split(",", var.internal_subnets_cidrs),
  )
}

# Create cloudwatch log group for vpc flow logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "${var.app_name}-vpc-flow-logs-group"
  retention_in_days = 7
}

# Create vpc
resource "aws_vpc" "ops" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(
    var.tags,
    {
      "Name"                                  = format("%s", var.app_name)
      "kubernetes.io/cluster/${var.app_name}" = "shared"
    },
  )
}

# CIS 4.3 Ensure VPC flow logging is enabled in all VPCs (Scored)
resource "aws_flow_log" "vpc_flow_logs_vpc" {
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  iam_role_arn    = aws_iam_role.vpc_flow_logs.arn
  vpc_id          = aws_vpc.ops.id
  traffic_type    = "ALL"
}

# Create internet gateway
resource "aws_internet_gateway" "ops" {
  vpc_id = aws_vpc.ops.id
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-igw", var.app_name)
    },
  )
}

# Create internal subnets
resource "aws_subnet" "internal" {
  vpc_id = aws_vpc.ops.id
  cidr_block = element(
    split(",", var.internal_subnets_cidrs),
    count.index,
  )
  availability_zone = element(random_shuffle.az.result, count.index)
  count = length(
    split(",", var.internal_subnets_cidrs),
  )
  tags = merge(
    var.tags,
    var.internal_subnet_tags,
    {
      "Name" = format(
        "%s-subnet-internal-%s",
        var.app_name,
        element(random_shuffle.az.result, count.index),
      )
    },
  )
}

# Create external facing subnets
resource "aws_subnet" "external" {
  vpc_id = aws_vpc.ops.id
  cidr_block = element(
    split(",", var.external_subnets_cidrs),
    count.index,
  )
  availability_zone = element(random_shuffle.az.result, count.index)
  count = length(
    split(",", var.external_subnets_cidrs),
  )
  tags = merge(
    var.tags,
    var.external_subnet_tags,
    {
      "Name" = format(
        "%s-subnet-external-%s",
        var.app_name,
        element(random_shuffle.az.result, count.index),
      )
    },
  )
}

# Create public route table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ops.id
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-rt-public", var.app_name)
    },
  )
  propagating_vgws = []
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ops.id
}

resource "aws_eip" "nateip" {
  vpc = true
  count = length(
    split(",", var.external_subnets_cidrs),
  )
  tags = merge(
    var.tags,
    {
      "Name" = format(
        "%s-elastic-ip-%s",
        var.app_name,
        element(random_shuffle.az.result, count.index),
      )
    },
  )
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.ops.id

  count = length(
    split(",", var.internal_subnets_cidrs),
  )
  tags = merge(
    var.tags,
    {
      "Name" = format(
        "%s-rt-private-%s",
        var.app_name,
        element(random_shuffle.az.result, count.index),
      )
    },
  )
  propagating_vgws = []
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = element(aws_route_table.private.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.natgw.*.id, count.index)
  count = length(
    split(",", var.internal_subnets_cidrs),
  )
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = element(aws_eip.nateip.*.id, count.index)
  subnet_id     = element(aws_subnet.external.*.id, count.index)
  count = length(
    split(",", var.internal_subnets_cidrs),
  )
  depends_on = [aws_internet_gateway.ops]
  tags = merge(
    var.tags,
    {
      "Name" = format(
        "%s-nat-gway-%s",
        var.app_name,
        element(random_shuffle.az.result, count.index),
      )
    },
  )
}

resource "aws_route_table_association" "internal" {
  count = length(
    split(",", var.internal_subnets_cidrs),
  )
  subnet_id      = element(aws_subnet.internal.*.id, count.index)
  route_table_id = element(aws_route_table.private.*.id, count.index)
}

resource "aws_route_table_association" "external" {
  count = length(
    split(",", var.external_subnets_cidrs),
  )
  subnet_id      = element(aws_subnet.external.*.id, count.index)
  route_table_id = aws_route_table.public.id
}

# VPC Endpoint for S3
data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.ops.id
  service_name = data.aws_vpc_endpoint_service.s3.service_name
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count = length(
    split(",", var.internal_subnets_cidrs),
  )
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

# VPC Endpoint for DynamoDB
data "aws_vpc_endpoint_service" "dynamodb" {
  service = "dynamodb"
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id       = aws_vpc.ops.id
  service_name = data.aws_vpc_endpoint_service.dynamodb.service_name
}

resource "aws_vpc_endpoint_route_table_association" "private_dynamodb" {
  count = length(
    split(",", var.internal_subnets_cidrs),
  )
  vpc_endpoint_id = aws_vpc_endpoint.dynamodb.id
  route_table_id  = element(aws_route_table.private.*.id, count.index)
}

# CIS 4.4  Ensure the default security group restricts all traffic
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.ops.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  tags = merge(
    var.tags,
    {
      "Name" = "DO NOT USE"
    },
  )
}
