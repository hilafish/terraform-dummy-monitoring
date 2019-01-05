##################################################################################
# RESOURCES
##################################################################################


# IAM Role
resource "aws_iam_role" "consul-server-iam-role" {
  name  = "consul_server_iam_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


# IAM Policy
resource "aws_iam_policy" "consul-server-iam-policy" {
  name  = "consul_server_iam_policy"
  description = "Allow consul server to read tags- to join agents to consul."
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "ec2:DescribeTags",
      "Resource": "*"
    }
  ]
}
EOF
}

# Attach the policy
resource "aws_iam_policy_attachment" "consul-server-iam-policy-attachment" {
  name  = "consul_server_iam_policy_attachment"
  roles      = ["${aws_iam_role.consul-server-iam-role.name}"]
  policy_arn = "${aws_iam_policy.consul-server-iam-policy.arn}"
}

# Create the instance profile
resource "aws_iam_instance_profile" "consul-server-instance-profile" {
  name  = "consul_server_instance_profile"
  role = "${aws_iam_role.consul-server-iam-role.name}"
}

