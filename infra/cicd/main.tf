# terraform {
#   required_providers {
#     aws = { source = "hashicorp/aws", version = "~> 5.0" }
#     tls = { source = "hashicorp/tls", version = "~> 4.0" }
#   }
# }

# provider "aws" {
#   region = var.aws_region
# }

data "aws_caller_identity" "current" {}

# Pull GitHub OIDC thumbprint dynamically (no hardcoded values)
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

resource "aws_ecr_repository" "this" {
  name         = var.ecr_repo_name
  force_delete = true

  image_scanning_configuration { scan_on_push = true }
  encryption_configuration     { encryption_type = "AES256" }

  tags = var.tags
}


resource "aws_ecr_lifecycle_policy" "keep_latest_5" {
  repository = aws_ecr_repository.this.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 4 untagged (so latest + 4 = 5)"
        selection = {
          tagStatus     = "untagged"
          countType     = "imageCountMoreThan"
          countNumber   = 4
        }
        action = { type = "expire" }
      }
    ]
  })
}




# Policy to push/pull this repo
data "aws_iam_policy_document" "ecr_push_pull" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage",
      "ecr:DescribeImages"
    ]
    resources = [aws_ecr_repository.this.arn]
  }
}

resource "aws_iam_policy" "ecr_push_pull" {
  name   = "${var.ecr_repo_name}-ecr-push-pull"
  policy = data.aws_iam_policy_document.ecr_push_pull.json
}

# Trust policy for GitHub Actions (restrict to your repo + branch/tags)
data "aws_iam_policy_document" "gha_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/heads/${var.allowed_branch}",
        "repo:${var.github_owner}/${var.github_repo}:ref:refs/tags/*"
      ]
    }
  }
}

resource "aws_iam_role" "gha_ecr_push" {
  name               = "${var.ecr_repo_name}-gha-ecr-push"
  assume_role_policy = data.aws_iam_policy_document.gha_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.gha_ecr_push.name
  policy_arn = aws_iam_policy.ecr_push_pull.arn
}

output "account_id"   { value = data.aws_caller_identity.current.account_id }
output "ecr_repo_url" { value = aws_ecr_repository.this.repository_url }
output "gha_role_arn" { value = aws_iam_role.gha_ecr_push.arn }
