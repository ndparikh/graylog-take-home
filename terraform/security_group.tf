# Get VPC id
resource "aws_security_group" "allow_all_internal_traffic" {
  name        = "allow-all-internal-traffic"
  vpc_id      = data.aws_vpc.selected.id
  description = "Allow access for all internal traffic."

  tags = merge(var.tags, map("Name", "allow-all-internal-traffic"))

  ingress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = [aws_vpc.ops.cidr_block]
  }

  egress {
    from_port   = "0"
    to_port     = "0"
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
