# ═══════════════════════════════════════════════════════════════════
# route53.tf – Optional weighted routing for canary traffic shifts
#
# Enable by setting:
#   hosted_zone_id
#   domain_name
# ═══════════════════════════════════════════════════════════════════

variable "hosted_zone_id" {
  description = "Route 53 hosted zone ID"
  type        = string
  default     = null
}

variable "domain_name" {
  description = "DNS record name (e.g. api.example.com)"
  type        = string
  default     = null
}

# ── BLUE weighted record ──────────────────────────────────────────
resource "aws_route53_record" "blue" {
  count          = var.hosted_zone_id != null && var.domain_name != null ? 1 : 0
  zone_id        = var.hosted_zone_id
  name           = var.domain_name
  type           = "A"
  set_identifier = "blue"

  weighted_routing_policy {
    weight = 100
  }

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}

# ── GREEN weighted record ─────────────────────────────────────────
resource "aws_route53_record" "green" {
  count          = var.hosted_zone_id != null && var.domain_name != null ? 1 : 0
  zone_id        = var.hosted_zone_id
  name           = var.domain_name
  type           = "A"
  set_identifier = "green"

  weighted_routing_policy {
    weight = 0
  }

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}