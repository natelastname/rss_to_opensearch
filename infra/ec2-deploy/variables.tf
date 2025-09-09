variable "project" {
  type = string
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "instance_type" {
  type = string
  default = "t3.micro"
}

variable "volume_size_gb" {
  type = number
  default = 32
}

variable "my_ip_cidr" {
  type = string
  # set to "YOUR.IP.ADDR.0/32"!
  default = "0.0.0.0/0"
}

variable "attach_eip" {
  type = bool
  default = false
}

# SSH key options: either generate automatically, or bring your own public key
variable "generate_keypair" {
  type = bool
  default = true
}

variable "public_key_path"  {
  type = string
  default = "~/.ssh/id_rsa.pub"
}

# Paths to your compose files on your local machine.
# Put them next to these .tf files or point elsewhere.
variable "compose_file" {
  type = string
}

locals {
  compose_file_path = "${path.root}/${var.compose_file}"
}


# optional ("" to skip)
variable "env_file" {
  type = string
  default = ""
}
######################################################################
# IAM
######################################################################

# who am I? (no extra perms needed; uses STS GetCallerIdentity)
data "aws_caller_identity" "current" {}

# partition awareness (aws, aws-us-gov, aws-cn)
data "aws_partition" "current" {}

locals {
  partition  = data.aws_partition.current.partition
}


######################################################################
