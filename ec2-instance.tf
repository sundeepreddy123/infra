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
