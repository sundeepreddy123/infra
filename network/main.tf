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
# Public RT (shared by all public subnets)
resource "aws_route_table" "public" {
  count  = length(var.az_zones)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-public-rt-${count.index + 1}"
  }
}
# Default route from public RT to IGW
resource "aws_route" "public_internet_access" {
  count                  = length(var.az_zones)
  route_table_id         = aws_route_table.public[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
# Associate all public subnets → public RT
resource "aws_route_table_association" "public" {
  count          = length(var.az_zones)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public[count.index].id
}
# Private RTs (one per AZ → -> NAT in same AZ)
resource "aws_route_table" "private" {
  count  = length(var.az_zones)
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-private-rt-${count.index + 1}"
  }
}
# Default route from private RT → NAT
resource "aws_route" "private_nat_gateway" {
  count                  = length(var.az_zones)
  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat[count.index].id
}
# Associate private subnets → private RT per AZ
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
    cidr_blocks = ["0.0.0.0/0"]   # SSH allowed only from your IPs (NOT 0.0.0.0/0)
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
#resource "aws_network_acl" "main" {
#  vpc_id = aws_vpc.main.id

 # subnet_ids = concat(
 #   aws_subnet.public[*].id,
 #   aws_subnet.private[*].id
 # )

  # Inbound allow all
 # ingress {
  #  rule_number   = 100
  #  protocol      = "-1"
  #  rule_action   = "allow"
  #  cidr_block    = "0.0.0.0/0"
  #  from_port     = 0
   # to_port       = 0
  #}

  # Outbound allow all
  # egress {
  #  rule_number   = 100
  #  protocol      = "-1"
  # rule_action   = "allow"
  # cidr_block    = "0.0.0.0/0"
  # from_port     = 0
  # to_port       = 0
  #}

  #tags = {
   # Name = "${var.env}-nacl"
  #}
#}
//////create transit gateway //////////
resource "aws_ec2_transit_gteway" "this" {
  description  = "Main Transit Gateway"
  amazon_side_asn  = 64512            <------------ This can be change according to us

  tags = {
    Name = var.tgw_name
    Env  = "prod"
  }
}

//////////create transit gateway route table /////
resource "aws_ec2_transit_gateway_route_table" "main" {
  transit_gateway_id   =  aws_ec2_transit_gateway.this.id

  tags  = {
    Name = "${var.tgw_name}-rt"
  }
}

//////////// Attach VPCs to Transit Gateway ////////////
resource "aws_ec2_transit_gateway_vpc_attachment" "vpc_attachments" {
  for_each  =  toset(var.vpc_ids)


  transit_gateway_id  = aws_ec2_transit_gateway.this.id
  vpc_id              = each.value
  subnets_ids         = var.subnet_ids_per_vpc[index(var.vpc_ids, each.value)]

  tags  =  {
    Name  = "${var.tgw_name}-${each.value}-attachment"
  }
}

/////////// Associate each attachment with the Route Table //////////
resource "aws_ec2_transit_gateway_route_table_association" "assoc" {
  for_each   =  aws_ec2_transit_gateway_vpc_attachement.vpc_attachments


  transit_gateway_attachment_id  =  each.value.id
  transit_gateway_route_table_id  = aws_ec2_transit_gateway_route_table.main.id
}

////////// Add default static route (optional) //////////
resource "aws_ec2_transit_gateway_route" "default_route" {
  destiation_cidr_block          = "0.0.0.0/0"
  transit_gateway_route_table_id   = aws_ec2_transit_gateway_route_table.main.id
  transit_gateway_attachment_id    = aws_ec2_transit_gateway_vpc_attachment.vpc_attachments["vpc-12345678"].id
}

/////// Trnasit Gateway Peering ////////////
resource "aws_ec2_transit_gatewaay_peering_attachment" "peer" {
  peer_region          = "us-east-1"
  transit_gateway_id   = aws_ec2_transit_gateway.this.id
  peer_transit_gateway_id   = "tgw-0abcd12345efgh"

  tags = {
    Name  =  "tgw-peering-euw1-use1"
  }
}
