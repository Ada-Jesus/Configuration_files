locals {
  name_prefix = "${var.app_name}-${var.environment}"

  common_tags = merge(
    {
      App         = var.app_name
      Environment = var.environment
    },
    var.tags
  )
}