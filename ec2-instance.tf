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


resource "aws_instance" "linux_ec2" {
  ami                            =  var.linux_ami_id
  instance_type                  = var.instance_type
  subnet_id                      =  aws_subnet.public[0].id
  associate_public_ip_address    =  true
  vpc_security_group_ids         =  [aws_security_group.dev_linux_sg.id]

  # USERDATA: Enable password login + create user
  user_data  =  <<EQF
#!/bin/bash

# Enable password login
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Create root user
useradd root

# Set password
echo "root:Password123#" | chpasswd

# Restart SSH
systemctl restart sshd
EOF

  tags = {
    Name = "${var.env}-linux-dev"
    Env  = var.env
  }
}

resource "aws_security_group" "dev_linux_sg" {
  name   = "${var.env}-dev-linux-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH (dev only)"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # OK for dev only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "windows_ec2" {
  ami                         = var.windows_ami_id   # Windows Server 2022/2019
  instance_type               = var.windows_type
  subnet_id                   = aws_subnet.public[0].id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.dev_windows_sg.id]

  # THIS ENABLES PASSWORD LOGIN FOR WINDOWS
  user_data = <<EOF
<powershell>
net user Administrator "Password123!" 
</powershell>
EOF

  tags = {
    Name = "${var.env}-windows-dev"
    Env  = var.env
  }
}

resource "aws_security_group" "dev_windows_sg" {
  name   = "${var.env}-dev-windows-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "RDP (dev only)"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # OK only for dev
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


