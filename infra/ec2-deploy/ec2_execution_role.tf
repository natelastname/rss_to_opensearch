data "aws_iam_policy_document" "execution_role_trust" {
  statement {
    effect = "Allow"
    principals {
      # Only ec2 instances can assume this role.
      type = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = [
      # Trusted entities (those who have been granted permission) can
      # request temporary credentials allowing them to use the
      # privileges it grants.
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "ec2_execution" {
  name               = "${var.project}-ec2-execution-role"
  assume_role_policy = data.aws_iam_policy_document.execution_role_trust.json
  # optional:
  # path = "/"
  # tags = { Project = var.project }
}

# ---------- (Optional) attach managed policies the instance needs ----------

# SSM: lets you use Session Manager, run commands, etc.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Agent (if you'll ship metrics/logs)
resource "aws_iam_role_policy_attachment" "cw_agent" {
  role       = aws_iam_role.ec2_execution.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ECR read-only (if your instance pulls images from ECR)
resource "aws_iam_role_policy_attachment" "ecr_readonly" {
  role       = aws_iam_role.ec2_execution.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ---------- Instance Profile (this is what EC2 actually uses) ----------
resource "aws_iam_instance_profile" "ec2_execution" {
  name = "${var.project}-ec2-execution-profile"
  role = aws_iam_role.ec2_execution.name
  # optional:
  # path = "/"
  # tags = { Project = var.project }
}
