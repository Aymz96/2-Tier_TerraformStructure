# DB Tier!
# Move anything to do with the App Tier creation

# Creating the App Tier
resource "aws_subnet" "db_subnet" {
    vpc_id                      = var.vpc_id
    cidr_block                  = "10.0.37.0/24"
    availability_zone           = "eu-west-1a"
    tags = {
      Name                      = "${var.name}-private-subnet"
    }
}

# Creating NACLs
resource "aws_network_acl" "private-nacl" {
    vpc_id = var.vpc_id
    subnet_ids = [aws_subnet.db_subnet.id]

    ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.88.0/24"
    from_port  = 27017
    to_port    = 27017
  }
    ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.88.0/24"
    from_port  = 22
    to_port    = 22
  }
     egress {
     protocol   = "tcp"
     rule_no    = 120
     action     = "allow"
     cidr_block = "10.0.88.0/24"
     from_port  = 1025
     to_port    = 65535
  }
    tags = {
      Name = "${var.name}-Private-NACL"
    }
}

# Creating a new route table
resource "aws_route_table" "private" {
    vpc_id                      = var.vpc_id

      tags = {
        Name = "${var.name}-private-route_table"
      }
}

# Creating the route table association
resource "aws_route_table_association" "assoc" {
    subnet_id                   = aws_subnet.db_subnet.id
    route_table_id              = aws_route_table.private.id
}

# Creating a security group, linking it with VPC and attaching it to our instance
resource "aws_security_group" "db_security" {
  name        = "Aymz_security_Group_DB"
  description = "private db security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "Port 22 from public subnet"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.88.0/24"]
  }

  ingress {
    description = "inbound rules"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.88.0/24"]
  }

  ingress {
    description = "inbound rules"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.88.0/24"]
  }

  # Default outbound rules for SG is it lets everything out automaticly
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "${var.name}-DB-security_group"
  }
}

data "template_file" "db_init" {
  template = file("./scripts/db/init.sh.tpl")
}

# Launching an Instance
resource "aws_instance" "db_instance" {
    ami                         = var.db_ami_id
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.db_subnet.id
    vpc_security_group_ids      = [aws_security_group.db_security.id]
    tags = {
        Name                    = var.name
    }
    key_name                    = "Aymz_vpc"

    user_data = data.template_file.db_init.rendered
}
