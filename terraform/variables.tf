variable "domain_name" {
  type = string
}

variable "jwks_uri" {
  type = string
}

variable "audience" {
  type = string
}

variable "token_issuer" {
  type = string
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
