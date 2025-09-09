output "instance_id" { value = aws_instance.this.id }
output "public_ip"   {
  value = try(aws_eip.this[0].public_ip, aws_instance.this.public_ip)
}

locals {
  ssh_user = "ubuntu"
  # Prefer EIP if present; fall back to the instance public IP
  ssh_host = try(aws_eip.this[0].public_ip, aws_instance.this.public_ip)
  # Pick the identity file path based on whether we generated a keypair
  ssh_key  = var.generate_keypair ? "${path.module}/ssh_${var.project}.pem" : "<your-private-key.pem>"
}

output "ssh_command" {
  value = "ssh -i ${local.ssh_key} ${local.ssh_user}@${local.ssh_host}"
}
output "service_name" { value = "${var.project}.service" }
output "compose_dir"  { value = "/opt/${var.project}" }
