# ═══════════════════════════════════════════════════════════════════
# SSM PARAMETERS – CLEAN VERSION
# ═══════════════════════════════════════════════════════════════════

resource "aws_ssm_parameter" "api_key" {
  name      = "/${var.app_name}/${var.environment}/api-key"
  type      = "SecureString"
  value     = "REPLACE_VIA_CI"
  overwrite = true
}

resource "aws_ssm_parameter" "db_connection" {
  name      = "/${var.app_name}/${var.environment}/db-connection-string"
  type      = "SecureString"
  value     = "REPLACE_VIA_CI"
  overwrite = true
}