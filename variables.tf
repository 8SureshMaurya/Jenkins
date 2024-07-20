
variable "region" {
  description = "The AWS region to create resources in"
  default     = "ap-southeast-2"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets"
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "ami_id" {
  description = "The AMI ID for the instances"
  default     = "ami-080660c9757080771"
}

variable "instance_type" {
  description = "The instance type"
  default     = "t2.micro"
}

