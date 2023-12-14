variable "api_role_name" {
  description = "Name of the API role"
  type        = string
}

variable "api_role_arn" {
  description = "ARN of the API role"
  type        = string
}

variable "rest_api_id" {
  description = "ID of the associated REST API"
  type        = string
}

variable "error_model_name" {
  description = "Name of the error model"
  type        = string
}

variable "poll_resource_id" {
  description = "ID of the poll resource"
  type        = string
}

variable "custom_authorizer_id" {
  description = "Custom authorizer id"
  type        = string
}

variable "public_poll_resource_id" {
  description = "ID of the public poll resource"
  type        = string
}

variable "lambda_logging_policy_arn" {
  description = "ARN of the Lambda logging policy"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "single_table_name" {
  description = "Name of the single table"
  type        = string
}

variable "single_table_arn" {
  description = "ARN of the single table"
  type        = string
}
