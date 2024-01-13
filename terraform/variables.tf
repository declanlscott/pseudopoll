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
