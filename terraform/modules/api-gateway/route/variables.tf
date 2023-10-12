variable "api_id" {
  description = "API identifier"
  type        = string
}

variable "route_key" {
  description = "Route key for the route"
  type        = string
}

variable "integration_subtype" {
  description = "AWS service action to invoke"
  type        = string
}

variable "request_parameters" {
  description = "(Optional) A key-value map specifying parameters that are passed to AWS_PROXY integrations"
  type        = map(string)
  default     = null
}

variable "credentials_arn" {
  description = "(Optional) Credentials required for the integration, if any"
  type        = string
  default     = null
}
