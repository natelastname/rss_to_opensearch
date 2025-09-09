terraform {
  required_providers {
    # “provider” is used in the sense of “hosting provider”
    # For example, we might require aws or azure
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

module "cicd" {
  source = "./cicd"
  ecr_repo_name = var.project
  aws_region = var.aws_region
  github_owner = "natelastname"
  github_repo = var.project
  allowed_branch = "master"
}

module "ec2-deploy" {
  source = "./ec2-deploy"
  project = var.project
  region = var.aws_region
  instance_type = "t3.micro"
  volume_size_gb = 32
  my_ip_cidr = "0.0.0.0/0"
  attach_eip = false
  generate_keypair = true
  public_key_path = "~/.ssh/id_rsa.pub"
  compose_file = "../docker-compose.yml"
}
