# App Tier
# Move anything to do with the App Tier creation

# Creating the App Tier
resource "aws_subnet" "app_subnet" {
    vpc_id                      = var.vpc_id
    cidr_block                  = "10.0.88.0/24"
    availability_zone           = "eu-west-1a"
    tags = {
      Name                      = "${var.name}-public-subnet"
    }
}

# Creating NACLs
resource "aws_network_acl" "public-nacl" {
    vpc_id = var.vpc_id
    subnet_ids = [aws_subnet.app_subnet.id]

    ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
    ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
    ingress {
    protocol   = "tcp"
    rule_no    = 120
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 3000
    to_port    = 3000
  }

    ingress {
    protocol   = "tcp"
    rule_no    = 130
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

    ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "allow"
    cidr_block = "${var.my_ip}/32" # my ip
    from_port  = 22
    to_port    = 22
  }
    egress {
   protocol   = -1
   rule_no    = 100
   action     = "allow"
   cidr_block = "0.0.0.0/0"
   from_port  = 0
   to_port    = 0
 }

    tags = {
      Name = "${var.name}-Public-NACL"
    }
}

# Creating a security group, linking it with VPC and attaching it to our instance
resource "aws_security_group" "app_security" {
  name        = "Aymz_security_Group_App"
  description = "Security Group port 80 traffic"
  vpc_id      = var.vpc_id

  ingress {
    description = "inbound rules"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "inbound rules"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "inbound rules"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.my_ip}/32", "10.0.88.0/24"]
  }

  ingress {
    description = "inbound rules"
    from_port  = 1024
    to_port    = 65535
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  # Default outbound rules for SG is it lets everything out automaticly
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "${var.name}-security_group"
  }
}

# Creating a new route table
resource "aws_route_table" "public" {
    vpc_id                      = var.vpc_id
    route {
      cidr_block                = "0.0.0.0/0"
      gateway_id                = var.igw_var
    }
      tags = {
        Name = "${var.name}-public-route_table"
      }
}

# Creating the route table association
resource "aws_route_table_association" "assoc" {
    subnet_id                   = aws_subnet.app_subnet.id
    route_table_id              = aws_route_table.public.id
}

# Data handler to call the template file (scripts)
data "template_file" "app_init" {
  template = file("./scripts/app/init.sh.tpl")
    vars = {
      db_priv_ip = var.db_ip
  }
  # The .tpl is similar to .erb in terms of it allows us to interpolate variables into static templates.
  # Making them# The .tpl is similar to .erb in terms of it allows us to interpolate variables into static templates.
  # Making them dynamic
  # vars = {
  #   my_name = "${var.name} is the real Aymz"
  # }
  # Then add echo "${my_name}" in the script file

  # The vars can be used to set ports, monogodb (to set private_ip for db_host)
  # AWS gives us new IPs - if we want to make one machine aware of another, this could be useful
}

# Launching an Instance
resource "aws_instance" "app_instance" {
    ami                         = var.ami_id
    instance_type               = "t2.micro"
    associate_public_ip_address = true
    subnet_id                   = aws_subnet.app_subnet.id
    vpc_security_group_ids      = [aws_security_group.app_security.id]
    tags = {
        Name                    = var.name
    }
    key_name                    = "Aymz_vpc"

    user_data = data.template_file.app_init.rendered

    # connection {
    #   user = "ubuntu"
    #   type = "ssh"
    #   host = self.public_ip
    #   private_key = "${file("~/.ssh/Aymz_vpc.pem")}"
    # }
    #
    # provisioner "remote-exec" {
    #   inline = [
    #    "cd /home/ubuntu/app",
    #    "sudo npm start &",
    #    # (&) Sends processes to the background
    #    # "PID=$!",
    #    # "sleep 2s",
    #    # "kill -INT $PID"
    #  ]
}
