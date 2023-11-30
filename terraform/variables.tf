variable "domain_name" {
  type = string
}

variable "jwks_uri" {
  type    = string
  default = "https://www.googleapis.com/oauth2/v3/certs"
}

variable "audience" {
  type      = string
  sensitive = true
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
