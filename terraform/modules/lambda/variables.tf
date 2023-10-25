variable "function_name" {
  description = "Unique name for your lambda function"
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

variable "role_arn" {
  description = "Amazon Resource Name (ARN) of the function's execution role. The role provides the function's identity and access to AWS services and resources."
  type        = string
}

variable "environment_variables" {
  description = "Map of environment variables that are accessible from the function code during execution"
  type        = map(string)
  default     = null
}
