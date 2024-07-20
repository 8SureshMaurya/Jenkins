provider "aws" {
  region = "ap-southeast-2"
}

# VPC
resource "aws_vpc" "ninja_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "ninja-vpc-01"
  }
}

# Subnets
resource "aws_subnet" "ninja_pub_sub" {
  count             = 2
  vpc_id            = aws_vpc.ninja_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ninja_vpc.cidr_block, 8, count.index)
  availability_zone = element(["ap-southeast-2a", "ap-southeast-2b"], count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "ninja-pub-sub-${count.index + 1}"
  }
}

resource "aws_subnet" "ninja_priv_sub" {
  count             = 2
  vpc_id            = aws_vpc.ninja_vpc.id
  cidr_block        = cidrsubnet(aws_vpc.ninja_vpc.cidr_block, 8, count.index + 2)
  availability_zone = element(["ap-southeast-2a", "ap-southeast-2b"], count.index)
  tags = {
    Name = "ninja-priv-sub-${count.index + 1}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "ninja_igw" {
  vpc_id = aws_vpc.ninja_vpc.id
  tags = {
    Name = "ninja-igw-01"
  }
}

# NAT Gateway
resource "aws_eip" "ninja_eip" {
  depends_on = [aws_internet_gateway.ninja_igw]
}

resource "aws_nat_gateway" "ninja_nat" {
  allocation_id = aws_eip.ninja_eip.id
  subnet_id     = aws_subnet.ninja_pub_sub[0].id
  tags = {
    Name = "ninja-nat-01"
  }
}

# Route Tables
resource "aws_route_table" "ninja_route_pub" {
  vpc_id = aws_vpc.ninja_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ninja_igw.id
  }
  tags = {
    Name = "ninja-route-pub-01"
  }
}

resource "aws_route_table_association" "pub_association" {
  count          = 2
  subnet_id      = aws_subnet.ninja_pub_sub[count.index].id
  route_table_id = aws_route_table.ninja_route_pub.id
}

resource "aws_route_table" "ninja_route_priv" {
  vpc_id = aws_vpc.ninja_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ninja_nat.id
  }
  tags = {
    Name = "ninja-route-priv-01"
  }
}

resource "aws_route_table_association" "priv_association" {
  count          = 2
  subnet_id      = aws_subnet.ninja_priv_sub[count.index].id
  route_table_id = aws_route_table.ninja_route_priv.id
}

# Bastion Host (public instance)
resource "aws_instance" "bastion" {
  ami           = "ami-080660c9757080771"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ninja_pub_sub[0].id
  tags = {
    Name = "ninja-bastion-host"
  }
}

# Private Instance
resource "aws_instance" "private_instance" {
  ami           = "ami-080660c9757080771"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.ninja_priv_sub[0].id
  tags = {
    Name = "ninja-private-instance"
  }
}
