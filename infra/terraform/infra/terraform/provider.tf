# ═══════════════════════════════════════════════════════════════════
# provider.tf – Terraform + AWS provider + remote state backend
# ═══════════════════════════════════════════════════════════════════

terraform {
  required_version = ">= 1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state (replace with your real bucket)
  backend "s3" {
    bucket         = "REPLACE_WITH_REAL_TF_STATE_BUCKET"
    key            = "blue-green/ecs/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = merge(
      {
        Application = var.app_name
        Environment = var.environment
        ManagedBy   = "Terraform"
      },
      var.tags
    )
  }
}

# ── Data sources used across multiple files ──────────────────────
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

# ── Local values shared across all files ─────────────────────────
locals {
  name_prefix = "${var.app_name}-${var.environment}"
}