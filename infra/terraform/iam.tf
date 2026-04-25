# ═══════════════════════════════════════════════════════════════════
# IAM ROLES – ECS TASK + EXECUTION ROLE (FIXED)
# ═══════════════════════════════════════════════════════════════════

data "aws_iam_policy_document" "ecs_task_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ═══════════════════════════════════════════════════════════════════
# EXECUTION ROLE (PULL IMAGE + LOGS + SSM SECRETS)
# ═══════════════════════════════════════════════════════════════════

resource "aws_iam_role" "task_execution" {
  name               = "${local.name_prefix}-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

# AWS managed ECS execution policy
resource "aws_iam_role_policy_attachment" "task_execution_base" {
  role       = aws_iam_role.task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ═══════════════════════════════════════════════════════════════════
# 🔥 THIS IS THE PART YOU WERE ASKING "WHERE DOES IT GO?"
# ═══════════════════════════════════════════════════════════════════

resource "aws_iam_role_policy" "task_execution_ssm" {
  name = "${local.name_prefix}-ssm-access"
  role = aws_iam_role.task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMReadAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.app_name}/*"
      },
      {
        Sid    = "SecretsManagerAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "*"
      }
    ]
  })
}

# ═══════════════════════════════════════════════════════════════════
# TASK ROLE (APP RUNTIME PERMISSIONS)
# ═══════════════════════════════════════════════════════════════════

resource "aws_iam_role" "task" {
  name               = "${local.name_prefix}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume.json
}

resource "aws_iam_role_policy" "task_app" {
  name = "${local.name_prefix}-task-app-policy"
  role = aws_iam_role.task.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SSMReadOnly"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/${var.app_name}/*"
      }
    ]
  })
}

# ═══════════════════════════════════════════════════════════════════
# OUTPUTS
# ═══════════════════════════════════════════════════════════════════

output "task_execution_role_arn" {
  value = aws_iam_role.task_execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.task.arn
}