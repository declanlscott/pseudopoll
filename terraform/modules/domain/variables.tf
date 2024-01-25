variable "cloudflare_api_token" {
  description = "The Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "The Cloudflare zone ID for the root domain"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "The Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "cloudflare_pages_project_name" {
  description = "The Cloudflare Pages project name"
  type        = string
}
