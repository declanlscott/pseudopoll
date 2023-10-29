variable "name" {
  description = "Name of the API. Must be less than or equal to 128 characters in length."
  type        = string
}

variable "redeployment_trigger_hashes" {
  description = "List of hashes that will trigger a redeployment of the API."
  type        = list(string)
}

variable "domain_name" {
  description = "'api' will be the subdomain of this domain (e.g. api.domain.com)"
  type        = string
}

variable "zone_id" {
  description = "Route53 zone ID for the domain"
  type        = string
}
