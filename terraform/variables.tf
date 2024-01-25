variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}

variable "auth_js_secret" {
  description = "Secret used to sign JWTs"
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "Google OAuth client ID"
  type        = string
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth client secret"
  type        = string
  sensitive   = true
}

variable "whitelist_enabled" {
  description = "Whether to enable the whitelist"
  type        = bool
  default     = false
}

variable "whitelist_users" {
  description = "CSV of user IDs that are allowed to log in"
  type        = string
  sensitive   = true
}

variable "jwks_uri" {
  type    = string
  default = "https://www.googleapis.com/oauth2/v3/certs"
}

variable "token_issuer" {
  type    = string
  default = "https://accounts.google.com"
}

variable "nanoid_alphabet" {
  type        = string
  description = "Alphabet used for nanoid generation"
  default     = "0123456789abcdefghijklmnopqrstuvwxyz"
}

variable "nanoid_length" {
  type        = number
  description = "Length of the nanoid"
  default     = 12
}

variable "prompt_min_length" {
  type        = number
  description = "Minimum length of the prompt"
  default     = 1
}

variable "prompt_max_length" {
  type        = number
  description = "Maximum length of the prompt"
  default     = 280
}

variable "option_min_length" {
  type        = number
  description = "Minimum length of the option"
  default     = 1
}

variable "option_max_length" {
  type        = number
  description = "Maximum length of the option"
  default     = 35
}

variable "min_options" {
  type        = number
  description = "Minimum number of options"
  default     = 2
}

variable "max_options" {
  type        = number
  description = "Maximum number of options"
  default     = 10
}

variable "min_duration" {
  type        = number
  description = "Minimum duration of the poll"
  default     = 60
}

variable "max_duration" {
  type        = number
  description = "Maximum duration of the poll"
  default     = 604800
}

variable "iot_custom_authorizer_name" {
  description = "The name of the IoT custom authorizer"
  type        = string
  default     = "pseudopoll-iot-authorizer"
}
