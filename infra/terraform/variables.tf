# ═══════════════════════════════════════════════════════════════════
# variables.tf – All input variables (hardened for CI/CD)
# ═══════════════════════════════════════════════════════════════════

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Application name used as resource prefix"
  type        = string
  default     = "aspnet-api"
}

variable "environment" {
  description = "Deployment environment (production, staging)"
  type        = string
  default     = "production"
}

# ── Container configuration ───────────────────────────────────────
variable "container_port" {
  description = "Port the container listens on (must match app + ALB + scripts)"
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "CPU must be a valid Fargate value (256–4096)."
  }
}

variable "memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 1024

  validation {
    condition     = var.memory >= 512
    error_message = "Memory must be at least 512 MB."
  }
}

variable "desired_count" {
  description = "Number of running tasks per ECS service"
  type        = number
  default     = 2
}

variable "ecr_image_uri" {
  description = "Full ECR image URI including tag (required for deployments)"
  type        = string
}

# ── Networking ────────────────────────────────────────────────────
variable "vpc_id" {
  description = "VPC ID to deploy resources into"
  type        = string
}

variable "private_subnets" {
  description = "Private subnets for ECS tasks"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnets for ALB"
  type        = list(string)
}

# ── TLS / ALB ─────────────────────────────────────────────────────
variable "certificate_arn" {
  description = "ACM certificate ARN (optional HTTPS)"
  type        = string
  default     = ""
}

variable "alb_deletion_protection" {
  description = "Enable ALB deletion protection"
  type        = bool
  default     = true
}

# ── Auto scaling ──────────────────────────────────────────────────
variable "autoscaling_min" {
  description = "Minimum ECS tasks"
  type        = number
  default     = 2
}

variable "autoscaling_max" {
  description = "Maximum ECS tasks"
  type        = number
  default     = 10
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage"
  type        = number
  default     = 70
}

# ── Logging ───────────────────────────────────────────────────────
variable "log_retention_days" {
  description = "CloudWatch log retention"
  type        = number
  default     = 30
}

# ── Metadata ──────────────────────────────────────────────────────
variable "tags" {
  description = "Global tags applied to all resources"
  type        = map(string)
  default     = {}
}
