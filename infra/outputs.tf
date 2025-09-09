
######################################################################
# CI/CD
######################################################################
output "account_id"   { value = module.cicd.account_id }
output "ecr_repo_url" { value = module.cicd.ecr_repo_url }
output "gha_role_arn" { value = module.cicd.gha_role_arn }


######################################################################
# EC2
######################################################################
output "ec2_ssh_command" { value = module.ec2-deploy.ssh_command }
output "ec2_instance_id" { value = module.ec2-deploy.instance_id }
output "ec2_public_ip" { value = module.ec2-deploy.public_ip }
