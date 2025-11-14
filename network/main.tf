# ------------------------------
# VPC
# ------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.env}-vpc"
  }
}

# ------------------------------
# Public Subnets
# ------------------------------
resource "aws_subnet" "public" {
  count             = length(var.az_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  map_public_ip_on_launch = true
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "${var.env}-public-${count.index + 1}"
    Tier = "Public"
  }
}

# ------------------------------
# Private Subnets
# ------------------------------
resource "aws_subnet" "private" {
  count             = length(var.az_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone = element(var.availability_zones, count.index)
  tags = {
    Name = "${var.env}-private-${count.index + 1}"
    Tier = "Private"
  }
}

# ------------------------------
# Internet Gateway
# ------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.env}-igw"
  }
}

# ------------------------------
# Elastic IPs for NAT
# ------------------------------
resource "aws_eip" "nat" {
  count  = length(var.az_zones)
  domain = "vpc"
  tags = {
    Name = "${var.env}-nat-eip-${count.index + 1}"
  }
}


# ------------------------------
# NAT Gateways
# ------------------------------
resource "aws_nat_gateway" "nat" {
  count         = length(var.az_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = {
    Name = "${var.env}-nat-${count.index + 1}"
  }
  depends_on = [aws_internet_gateway.igw]
}

# ------------------------------
# Route Tables
# ------------------------------
# Public Route Table
resource "aws_route_table" "public" {
  count  = length(var.az_zones)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-public-rt-${count.index + 1}"
  }
}

resource "aws_route" "public_internet_access" {
  count                  = length(var.az_zones)
  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.az_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}

# Private Route Tables (one per AZ)
resource "aws_route_table" "private" {
  count  = length(var.az_zones)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-private-rt-${count.index + 1}"
  }
}

resource "aws_route" "private_nat_gateway" {
  count                  = length(var.az_zones)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}

resource "aws_route_table_association" "private" {
  count          = length(var.az_zones)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}


# ------------------------------
# Security Group
# ------------------------------
resource "aws_security_group" "default" {
  name        = "${var.env}-default-sg"
  description = "Default SG for ${var.env}"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-sg"
  }
}

# ------------------------------
# Network ACL
# ------------------------------
resource "aws_network_acl" "main" {
  vpc_id = aws_vpc.main.id

  subnet_ids = concat(
    aws_subnet.public[*].id,
    aws_subnet.private[*].id
  )

  # Inbound allow all
  ingress {
    rule_number   = 100
    protocol      = "-1"
    rule_action   = "allow"
    cidr_block    = "0.0.0.0/0"
    from_port     = 0
    to_port       = 0
  }

  # Outbound allow all
  egress {
    rule_number   = 100
    protocol      = "-1"
    rule_action   = "allow"
    cidr_block    = "0.0.0.0/0"
    from_port     = 0
    to_port       = 0
  }

  tags = {
    Name = "${var.env}-nacl"
  }
}
