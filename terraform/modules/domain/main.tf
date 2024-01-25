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

resource "cloudflare_pages_domain" "frontend" {
  account_id   = var.cloudflare_account_id
  project_name = var.cloudflare_pages_project_name
  domain       = var.domain_name
}

resource "cloudflare_record" "frontend" {
  zone_id = var.cloudflare_zone_id

  name  = "@"
  value = "${var.cloudflare_pages_project_name}.pages.dev"
  type  = "CNAME"
}

resource "cloudflare_record" "www" {
  zone_id = var.cloudflare_zone_id

  name    = "www"
  value   = "100::"
  type    = "AAAA"
  proxied = true
}

resource "cloudflare_list" "list" {
  account_id = var.cloudflare_account_id
  name       = "pseudopoll"
  kind       = "redirect"
}

resource "cloudflare_list_item" "www" {
  account_id = var.cloudflare_account_id
  list_id    = cloudflare_list.list.id

  redirect {
    source_url            = "www.${var.domain_name}/"
    target_url            = "https://${var.domain_name}/"
    status_code           = 301
    preserve_query_string = true
    include_subdomains    = false
    subpath_matching      = true
    preserve_path_suffix  = true
  }
}

# TODO: Figure out API token permissions for this to work
# in the meantime, we'll just use the Cloudflare dashboard
# to create the bulk redirect rule
# resource "cloudflare_ruleset" "redirects" {
#   zone_id = var.cloudflare_zone_id
#   name    = "pseudopoll"
#   kind    = "root"
#   phase   = "http_request_redirect"

#   rules {
#     action      = "redirect"
#     description = "Apply redirects from list"
#     enabled     = true

#     action_parameters {
#       from_list {
#         name = cloudflare_list.list.name
#         key  = "http.request.full_uri"
#       }
#     }

#     expression = "http.request.full_uri in $pseudopoll"
#   }
# }
