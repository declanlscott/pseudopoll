terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.23.0"
    }
  }
}

provider "cloudflare" {
  # Configuration options
  api_token = var.cloudflare_api_token
}

locals {
  api_domain_name = "api.${var.domain_name}"
}

resource "aws_acm_certificate" "api" {
  domain_name       = local.api_domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "cloudflare_record" "api_validation" {
  zone_id = var.cloudflare_zone_id

  for_each = {
    for dvo in aws_acm_certificate.api.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name  = each.value.name
  value = each.value.record
  type  = each.value.type
}

resource "aws_acm_certificate_validation" "api_validation" {
  certificate_arn         = aws_acm_certificate.api.arn
  validation_record_fqdns = [for record in cloudflare_record.api_validation : record.hostname]
}

resource "aws_api_gateway_domain_name" "api" {
  domain_name              = local.api_domain_name
  regional_certificate_arn = aws_acm_certificate_validation.api_validation.certificate_arn

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "cloudflare_record" "api" {
  zone_id = var.cloudflare_zone_id

  name    = "api"
  type    = "CNAME"
  value   = aws_api_gateway_domain_name.api.regional_domain_name
  proxied = true
}
