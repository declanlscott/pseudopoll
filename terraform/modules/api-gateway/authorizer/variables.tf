variable "name" {
  description = "Name of the authorizer"
  type        = string
}

variable "rest_api_id" {
  description = "ID of the associated REST API"
  type        = string
}

variable "lambda_role_arn" {
  description = "Amazon Resource Name (ARN) specifying the role for the authorizer lambda"
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
