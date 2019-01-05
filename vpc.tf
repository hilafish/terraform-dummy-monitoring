##################################################################################
# VARIABLES
##################################################################################

variable "Virginia-VPC_address_space" {
  default = "10.1.0.0/16"
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #
resource "aws_vpc" "Virginia-VPC" {
  cidr_block = "${var.Virginia-VPC_address_space}"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags {
    Name        = "VPC-Virginia"
  }
}

resource "aws_internet_gateway" "IGW-Virginia-VPC" {
  vpc_id = "${aws_vpc.Virginia-VPC.id}"

  tags {
    Name        = "IGW-VPC-Virginia"
  }
}

resource "aws_eip" "Virginia-VPC-nat_eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.IGW-Virginia-VPC"]
  
  tags {
    Name = "VPC-NAT_EIP-Virginia"
  }
}

resource "aws_nat_gateway" "NATGW-Virginia-VPC" {
  allocation_id = "${aws_eip.Virginia-VPC-nat_eip.id}"
  subnet_id     = "${aws_subnet.pub_subnet.id}"
  
  tags {
    Name = "NATGW-Virginia-VPC"
  }
  
  depends_on = ["aws_internet_gateway.IGW-Virginia-VPC"]
}

resource "aws_subnet" "pub_subnet" {
  cidr_block              = "${cidrsubnet(var.Virginia-VPC_address_space, 8, count.index + 1)}"
  vpc_id                  = "${aws_vpc.Virginia-VPC.id}"
  map_public_ip_on_launch = "true"

  tags {
    Name        = "pub_subnet-VPC-Virginia"
  }
}

resource "aws_subnet" "priv_subnet" {
  cidr_block              = "${cidrsubnet(var.Virginia-VPC_address_space, 8, count.index + 3)}"
  vpc_id                  = "${aws_vpc.Virginia-VPC.id}"
  map_public_ip_on_launch = "false"

  tags {
    Name        = "priv_subnet-VPC-Virginia"
  }
}

# ROUTING #
resource "aws_route_table" "Virginia-VPC-pub-rt" {
  vpc_id = "${aws_vpc.Virginia-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.IGW-Virginia-VPC.id}"
  }
  
  tags {
    Name        = "pub-rt-VPC-Virginia"
  }
}

resource "aws_route_table_association" "Virginia-VPC-pub-rta" {
  subnet_id      = "${aws_subnet.pub_subnet.id}"
  route_table_id = "${aws_route_table.Virginia-VPC-pub-rt.id}"
}

resource "aws_route_table" "Virginia-VPC-priv-rt" {
  vpc_id = "${aws_vpc.Virginia-VPC.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.NATGW-Virginia-VPC.id}"
  }
  
  tags {
    Name = "priv-rt-VPC-Virginia"
    }
}

resource "aws_route_table_association" "Virginia-VPC-priv-rta" {
  subnet_id      = "${aws_subnet.priv_subnet.id}"
  route_table_id = "${aws_route_table.Virginia-VPC-priv-rt.id}"
}
