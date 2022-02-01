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
