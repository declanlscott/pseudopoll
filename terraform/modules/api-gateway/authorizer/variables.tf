variable "function_name" {
  description = "Unique name for your custom authorizer's lambda function"
  type        = string
}

variable "name" {
  description = "Name of the authorizer"
  type        = string
}

variable "rest_api_id" {
  description = "ID of the associated REST API"
  type        = string
}

variable "archive_source_file" {
  description = "Package this file into the archive"
  type        = string
}

variable "archive_output_path" {
  description = "The output of the archive file"
  type        = string
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

variable "lambda_logging_policy_arn" {
  description = "ARN of the Lambda logging policy"
  type        = string
}
