provider "aws" {
  version = "~> 5.0"
  region  = "us-east-1"
}

data "aws_ami" "dev_ami" {
  most_recent = true
  filter {
    name   = "tag:Env"
    values = ["dev"]
  }

}
