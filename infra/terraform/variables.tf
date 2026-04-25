variable "aws_region" {
  default = "us-east-1"
}

variable "app_name" {
  default = "aspnet-api"
}

variable "environment" {
  default = "production"
}

variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "image_uri" {
  type = string
}

variable "container_port" {
  default = 8080
}

variable "cpu" {
  default = 512
}

variable "memory" {
  default = 1024
}

variable "desired_count" {
  default = 2
}

variable "autoscaling_min" { default = 2 }
variable "autoscaling_max" { default = 10 }
variable "autoscaling_cpu_target" { default = 70 }

variable "certificate_arn" {
  default = ""
}

variable "alb_deletion_protection" {
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention days"
  type        = number
  default     = 7
}

variable "container_name" {
  description = "ECS container name (must match task definition)"
  type        = string
  default     = "aspnet-api"
}

variable "ecr_image_uri" {
  description = "Full ECR image URI"
  type        = string
}
variable "private_route_table_ids" {
  description = "Route table IDs for private subnets (required for S3 Gateway endpoint)"
  type        = list(string)
}

