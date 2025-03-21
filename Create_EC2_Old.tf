terraform {
  required_providers {
    aws  = {
        source = "hashicorp/aws"
        version = ">= 5.25.0"
    }
  }
}

locals{
  az_location = "ap-northeast-1a"
}

resource "aws_vpc""test"{
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
  tags = {
    Name = "My-VPC"
  }
}

resource "aws_subnet" "pub-sub"{
  vpc_id = aws_vpc.test.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = local.az_location
  tags = {
    Name = "My-Public-Subnet"
  }
  depends_on = [ 
    aws_vpc.test 
  ]
}

resource "aws_internet_gateway" "gw"{
  vpc_id = aws_vpc.test.id
  tags = {
    Name = "My-Internet-Gateway"
  }
  depends_on = [ 
    aws_vpc.test  
   ]
}

resource "aws_route_table" "public-rtbl"{
  vpc_id = aws_vpc.test.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "My-Public-Rtbl"
  }
  depends_on = [ 
    aws_internet_gateway.gw
   ]
}

resource "aws_route_table_association" "att-pubtbl"{
  route_table_id = aws_route_table.public-rtbl.id
  subnet_id = aws_subnet.pub-sub.id
}

resource "aws_security_group" "secgrp"{
  name = "Public Security Group"
  description = "Security Group for Public Instance"
  vpc_id = aws_vpc.test.id
  ingress{
    description = "Permit SSL Access"
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 22
    to_port = 22
  }
  ingress{
    description = "HTTP Access"
    cidr_blocks = ["0.0.0.0/0"]
    protocol = "tcp"
    from_port = 80
    to_port = 80
  }
  tags = {
    Name = "My-Public-Security-Group"
  }
}

resource "aws_network_interface" "my_nic" {
  subnet_id = aws_subnet.pub-sub.id
  security_groups = [aws_security_group.secgrp.id]
}

resource "aws_key_pair" "my_key"{
  key_name = "MyEC2Key"
  public_key = file("~/.ssh/MyEC2Key.pub")
  tags = {
    Name = "My-Key"
  }
}

resource "aws_instance" "my_instance"{
  credit_specification {
    cpu_credits = "standard"
  }
  instance_type = "t2.micro"
  key_name = aws_key_pair.my_key.key_name
  ami = "ami-078296f82eb463377"
  network_interface {
    device_index = "0"
    network_interface_id = aws_network_interface.my_nic.id
  }
  tags = {
    Name = "My-Public-Instance"
  }
}

output "instance_publicip_addr"{
  value = aws_instance.my_instance.public_ip
}

