provider "aws" {
  region = "eu-west-1"
}

# Create a VPC
# Resources are the references that exist inside AWS

resource "aws_vpc" "app_vpc" {
  cidr_block  = "10.0.0.0/16"
  tags = {
      name    = "${var.name}-VPC"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
  tags = {
  Name = "${var.name}-internet_gatway"
  }
}

# We dont need this aws_internet_gateway as we are now making our own igw above
# We can query our exsisting vpc/infrastructure with the 'data' handler function
# Attaching the IG to vpc
# data "aws_internet_gateway" "default-gw" {
#   filter {
#     # vpc-id (from the hasicorp docs, it references AWS-API that has this filter attachments)
#     name                        = "attachment.vpc-id"
#     values                      = [var.vpc_id]
#   }
# }

data "external" "myipaddr" {
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}

# Creates The DB Tier with all the variable that have been passed to it
module "db" {
  source      = "./modules/db_tier"
  vpc_id      = aws_vpc.app_vpc.id
  name        = "${var.name}_DB"
  db_ami_id      = var.db_ami_id
}

# Creates the App Tier with all the variables that have been passed to it
module "app" {
  source      = "./modules/app_tier"
  vpc_id      = aws_vpc.app_vpc.id
  name        = "${var.name}_App"
  igw_var     = aws_internet_gateway.igw.id
  ami_id      = var.ami_id
  db_ip = module.db.instance_ip_addr
  my_ip = data.external.myipaddr.result.ip
}


# ==============================    Definitions   ==============================

# VAR (using var your are able to call variables that have been assigned)

# RESOURCE declarations can include a number of advanced features, but only a small subset are required for initial use.
# you can call it using just the name from another resource.

# Data sources allow data to be fetched or computed for use elsewhere in Terraform configuration.
# A data block requests that Terraform read from a given data source ("aws_ami") and export the result under the given local name ("example").
