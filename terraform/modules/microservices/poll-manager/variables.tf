variable "rest_api_id" {
  description = "ID of the associated REST API"
  type        = string
}

variable "rest_api_execution_arn" {
  description = "Execution ARN of the associated REST API"
  type        = string
}

variable "stage_name" {
  description = "Name of the associated stage"
  type        = string
}

variable "parent_id" {
  description = "ID of the parent API resource"
  type        = string
}

variable "custom_authorizer_id" {
  description = "Custom authorizer id"
  type        = string
}

variable "nanoid_alphabet" {
  description = "Alphabet used for nanoid generation"
  type        = string
}

variable "nanoid_length" {
  description = "Length of the nanoid"
  type        = number
}

variable "lambda_logging_policy_arn" {
  description = "ARN of the Lambda logging policy"
  type        = string
}
