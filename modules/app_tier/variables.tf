variable "vpc_id" {
  description = "The VPC it launch resources into"
}

variable "name" {
  description = "The Name for the App "
}

variable "igw_var" {
  description = "The internet gateway id for the App"
}

variable "ami_id" {
  description = "The AMI ID for the App"
}
