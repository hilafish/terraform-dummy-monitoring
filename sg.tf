# SECURITY GROUPS #

resource "aws_security_group" "kibana-grafana-sg" {
  name   = "kibana_grafana_sg"
  vpc_id = "${aws_vpc.Virginia-VPC.id}"

  # access from anywhere

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 5601
    to_port     = 5601
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "prometheus-sg" {
  name   = "prometheus_sg"
  vpc_id = "${aws_vpc.Virginia-VPC.id}"

  # access from anywhere
  ingress {
    from_port   = 9090
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["${var.Virginia-VPC_address_space}"]
  }

  ingress {
    from_port   = 8300
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["${var.Virginia-VPC_address_space}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "dummy-exporter-sg" {
  name   = "dummy_exporter_sg"
  vpc_id = "${aws_vpc.Virginia-VPC.id}"

  # access from anywhere
  ingress {
    from_port   = 65433
    to_port     = 65433
    protocol    = "tcp"
    cidr_blocks = ["${var.Virginia-VPC_address_space}"]
  }

  ingress {
    from_port   = 8300
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["${var.Virginia-VPC_address_space}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "consul-sg" {
  name   = "consul_sg"
  vpc_id = "${aws_vpc.Virginia-VPC.id}"

  # access from anywhere

  ingress {
    from_port   = 8300
    to_port     = 8600
    protocol    = "tcp"
    cidr_blocks = ["${var.Virginia-VPC_address_space}"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "elastic-search-sg" {
  name   = "elastic_search_sg"
  vpc_id = "${aws_vpc.Virginia-VPC.id}"

  # access from anywhere
  ingress {
    from_port   = 9200
    to_port     = 9200
    protocol    = "tcp"
    cidr_blocks = ["${var.Virginia-VPC_address_space}"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
