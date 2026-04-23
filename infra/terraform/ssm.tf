# ═══════════════════════════════════════════════════════════════════
# SSM PARAMETERS – REQUIRED FOR ECS SECRETS
# ═══════════════════════════════════════════════════════════════════

resource "aws_ssm_parameter" "api_key" {
  name  = "/aspnet-api-production/api-key"
  type  = "SecureString"
  value = var.api_key

  overwrite = true
}

resource "aws_ssm_parameter" "db_connection" {
  name  = "/aspnet-api-production/db-connection-string"
  type  = "SecureString"
  value = var.db_connection_string

  overwrite = true
}