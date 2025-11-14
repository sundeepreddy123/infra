resource "aws_instance" "ubuntu" {
  ami        =  "ami-04XXXXXXXXX"
  instance_type    =  "t2.small"

  tags  =  {
    Name  =  "Ubuntu"
  }
}

resource "aws_instance" "ubuntu"  {
  ami    =  "ami-04XXXXXXXXXX"
  instance_type    =  "t2.small"

  tags  =  {
    Name  =  "ubuntu"
  }
}

resource "aws_security_group" "public_ec2_sg" {
  name        = "${var.env}-public-ec2-sg"
  description = "Public EC2 SG with secure rules"
  vpc_id      = aws_vpc.main.id  # SAME VPC

  # Allow HTTP publicly
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS publicly
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH ONLY from your IP
  ingress {
    description = "SSH restricted to your IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_ips
  }

  # Allow outbound to anywhere
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env}-public-ec2-sg"
    Env  = var.env
  }
}
