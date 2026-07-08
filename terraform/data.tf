
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}


data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = [var.ubuntu_ami_name_pattern]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = [var.ami_architecture]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}
