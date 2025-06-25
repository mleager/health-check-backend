data "aws_route53_zone" "primary" {
  name = var.route53_zone_name
}

resource "aws_route53_record" "subdomain_record" {
  zone_id = data.aws_route53_zone.primary.id
  name    = "api.${var.route53_zone_name}"
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }

}

resource "aws_acm_certificate" "certificate" {
  domain_name       = "api.${var.route53_zone_name}"
  validation_method = "DNS"
}

