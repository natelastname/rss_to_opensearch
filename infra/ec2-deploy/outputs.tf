output "instance_id" { value = aws_instance.this.id }
output "public_ip"   {
  value = try(aws_eip.this[0].public_ip, aws_instance.this.public_ip)
}

locals {
  # Prefer EIP if present; fall back to the instance public IP
  ssh_host = try(aws_eip.this[0].public_ip, aws_instance.this.public_ip)
  ssh_pubkey = aws_key_pair.this.public_key
  # Pick the identity file path based on whether we generated a keypair
  ssh_key  = var.generate_keypair ? "${path.module}/ssh_${var.project}.pem" : "<your-private-key.pem>"
}

output "ssh_command" {
  description = "Connect over SSH."
  value = "ssh -i ${local.ssh_key} ${var.deploy_user}@${local.ssh_host}"
}

output "ssm_command" {
  description = "Start an AWS SSM shell session to the instance."
  value       = "aws ssm start-session --target ${aws_instance.this.id}"
}


output "service_name" { value = "${var.project}.service" }
output "compose_dir"  { value = "/opt/${var.project}" }
