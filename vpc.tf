# ensure resource name is same as var.vpc_name
resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.vpc_name}"
    TF-Managed = true
  }
}

# subnets
resource "aws_subnet" "edge-a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.edge-a_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.vpc_name}-edge-a"
    TF-Managed = true
  }
}

resource "aws_subnet" "edge-b" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.edge-b_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "${var.vpc_name}-edge-b"
    TF-Managed = true
  }
}

resource "aws_subnet" "bastion-a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.bastion-a_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}a"
  tags = {
    Name = "${var.vpc_name}-bastion-a"
    TF-Managed = true
    Subnet-Name = "bastion"
  }
}

resource "aws_subnet" "bastion-b" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.bastion-b_cidr}"
  map_public_ip_on_launch = true
  availability_zone = "${var.aws_region}b"
  tags = {
    Name = "${var.vpc_name}-bastion-b"
    TF-Managed = true
    Subnet-Name = "bastion"
  }
}

resource "aws_subnet" "app-a" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.app-a_cidr}"
  availability_zone = "${var.aws_region}a"
  tags = {
    Name =  "${var.vpc_name}-app-a"
    TF-Managed = true
    Subnet-Name = "application"
  }
}

resource "aws_subnet" "app-b" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${var.app-b_cidr}"
  availability_zone = "${var.aws_region}b"
  tags = {
    Name =  "${var.vpc_name}-app-b"
    TF-Managed = true
    Subnet-Name = "application"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "${var.vpc_name}-igw"
    TF-Managed = true
  }
}

# elastic IPs
resource "aws_eip" "eip1" {
  vpc = true
  depends_on = ["aws_internet_gateway.igw"]
}

# resource "aws_eip" "eip2" {
#   vpc = true
#   depends_on = ["aws_internet_gateway.igw"]
# }

# nat gateways
resource "aws_nat_gateway" "nat_gw-a" {
  allocation_id = "${aws_eip.eip1.id}"
  subnet_id = "${aws_subnet.edge-a.id}"
  depends_on = ["aws_internet_gateway.igw"]
  tags = {
    Name = "${var.vpc_name}-nat_gw-a"
    TF-Managed = true
  }
}

# resource "aws_nat_gateway" "nat_gw-b" {
#   allocation_id = "${aws_eip.eip2.id}"
#   subnet_id = "${aws_subnet.edge-b.id}"
#   depends_on = ["aws_internet_gateway.igw"]
#   tags = {
#     Name = "${var.vpc_name}-nat_gw-b"
#     TF-Managed = true
#   }
# }

# public route table
resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.vpc_name}-public_route_table"
    TF-Managed = true
  }
}

# private route tables
resource "aws_route_table" "private_route_table-a" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.vpc_name}-private_route_table-a"
    TF-Managed = true
  }
}
 
resource "aws_route_table" "private_route_table-b" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "${var.vpc_name}-private_route_table-b"
    TF-Managed = true
  }
}
 
# create route for public route table (inclusive of all AZs)
resource "aws_route" "public_route" {
  route_table_id  = "${aws_route_table.public_route_table.id}"
  destination_cidr_block = "${var.default_gw_cidr}"
  gateway_id = "${aws_internet_gateway.igw.id}"
}

# associate subnet edge-a to public route table
resource "aws_route_table_association" "edge-a-association" {
  subnet_id = "${aws_subnet.edge-a.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

# associate subnet edge-b to public route table
resource "aws_route_table_association" "edge-b-association" {
  subnet_id = "${aws_subnet.edge-b.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

# associate subnet bastion-a to public route table
resource "aws_route_table_association" "bastion-a-association" {
  subnet_id = "${aws_subnet.bastion-a.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

# associate subnet bastion-b to public route table
resource "aws_route_table_association" "bastion-b-association" {
  subnet_id = "${aws_subnet.bastion-b.id}"
  route_table_id = "${aws_route_table.public_route_table.id}"
}

# create route for private route table for AZ a's on all subnets
resource "aws_route" "private_route_table-a" {
  route_table_id  = "${aws_route_table.private_route_table-a.id}"
  destination_cidr_block = "${var.default_gw_cidr}"
  nat_gateway_id = "${aws_nat_gateway.nat_gw-a.id}"
}

# create route for private route table for AZ b's on all subnets
resource "aws_route" "private_route_table-b" {
  route_table_id  = "${aws_route_table.private_route_table-b.id}"
  destination_cidr_block = "${var.default_gw_cidr}"
  # nat_gateway_id = "${aws_nat_gateway.nat_gw-b.id}"
  nat_gateway_id = "${aws_nat_gateway.nat_gw-a.id}"
}

# associate subnet app servers to private route table a
resource "aws_route_table_association" "app-a-association" {
  subnet_id = "${aws_subnet.app-a.id}"
  route_table_id = "${aws_route_table.private_route_table-a.id}"
}

# associate subnet app servers to private route table b
resource "aws_route_table_association" "app-b-association" {
  subnet_id = "${aws_subnet.app-b.id}"
  route_table_id = "${aws_route_table.private_route_table-b.id}"
}
