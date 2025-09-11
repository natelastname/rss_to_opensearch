locals {
  account_id = data.aws_caller_identity.current.account_id
}

# --- SSH key: generate or use existing ---
resource "tls_private_key" "gen" {
  count     = var.generate_keypair ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "this" {
  key_name   = "${var.project}-key"
  public_key = var.generate_keypair ? tls_private_key.gen[0].public_key_openssh : file(var.public_key_path)
}

resource "local_file" "private_key" {
  count    = var.generate_keypair ? 1 : 0
  content  = tls_private_key.gen[0].private_key_pem
  filename = "${path.module}/ssh_${var.project}.pem"
  file_permission = "0600"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# --- Security group: SSH (22) restricted + optional 80/443 for web uses ---
resource "aws_security_group" "this" {
  name        = "${var.project}-sg"
  description = "SG for ${var.project}"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Open if your compose stack needs these; comment out if not needed.

  # ingress {
  #   description = "HTTPS"
  #   from_port   = 443
  #   to_port     = 443
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   description = "HTTP"
  #   from_port   = 80
  #   to_port     = 80
  #   protocol    = "tcp"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
}


######################################################################

locals {
  files = [
    for fname in fileset("${path.module}/files", "*") : {
      name    = fname
      content = filebase64("${path.module}/files/${fname}")
    }
  ]
  # Render cloud-init
  userdata = templatefile("${path.module}/templates/cloud-init.yaml", {
    project     = var.project
    files       = local.files
    ssh_pubkey  = aws_key_pair.this.public_key
    deploy_user = var.deploy_user
  })
}


######################################################################


resource "aws_instance" "this" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.this.key_name
  vpc_security_group_ids = [aws_security_group.this.id]
  user_data              = local.userdata
  iam_instance_profile   = aws_iam_instance_profile.ec2_execution.name

  root_block_device {
    volume_size = var.volume_size_gb
  }

  tags = {
    Name    = var.project
    Project = var.project
  }

  # Force replace on user_data change
  user_data_replace_on_change = true

  # Optional zero-downtime pattern if you can run two at once:
  lifecycle { create_before_destroy = true }

}

# Optional stable public IP
resource "aws_eip" "this" {
  count  = var.attach_eip ? 1 : 0
  domain = "vpc"
  tags = { Project = var.project }
}

resource "aws_eip_association" "a" {
  count         = var.attach_eip ? 1 : 0
  instance_id   = aws_instance.this.id
  allocation_id = aws_eip.this[0].id
}

