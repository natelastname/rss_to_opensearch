variable "ecr_repo_name" {
  type = string
  default = "rss_to_opensearch"
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "github_owner" {
  type = string
  default = "natelastname"
}

variable "github_repo" {
  type = string
  default = "rss_to_opensearch"
}

variable "allowed_branch" {
  type = string
  default = "master"
}

variable "tags" {
  type = map(string)
  default = {}
}
