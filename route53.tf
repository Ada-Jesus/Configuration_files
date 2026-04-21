# ═══════════════════════════════════════════════════════════════════
#  route53.tf  –  Optional weighted routing for canary traffic shifts
#
#  Uncomment and set hosted_zone_id + domain_name to enable.
#  Weighted routing lets you send e.g. 10% to new ALB while
#  validating before cutting 100% – useful for canary deploys.
# ═══════════════════════════════════════════════════════════════════

# variable "hosted_zone_id" {
#   description = "Route 53 hosted zone ID"
#   type        = string
#   default     = ""
# }
#
# variable "domain_name" {
#   description = "DNS record name (e.g. api.example.com)"
#   type        = string
#   default     = ""
# }
#
# resource "aws_route53_record" "blue" {
#   zone_id        = var.hosted_zone_id
#   name           = var.domain_name
#   type           = "A"
#   set_identifier = "blue"
#
#   weighted_routing_policy {
#     weight = 100   # reduce to e.g. 90 during canary shift
#   }
#
#   alias {
#     name                   = aws_lb.main.dns_name
#     zone_id                = aws_lb.main.zone_id
#     evaluate_target_health = true
#   }
# }
#
# resource "aws_route53_record" "green" {
#   zone_id        = var.hosted_zone_id
#   name           = var.domain_name
#   type           = "A"
#   set_identifier = "green"
#
#   weighted_routing_policy {
#     weight = 0    # pipeline bumps this to 10, 50, 100 during shift
#   }
#
#   alias {
#     name                   = aws_lb.main.dns_name
#     zone_id                = aws_lb.main.zone_id
#     evaluate_target_health = true
#   }
# }
