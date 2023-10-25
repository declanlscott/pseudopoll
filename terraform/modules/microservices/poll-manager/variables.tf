variable "rest_api_id" {
  description = "ID of the associated REST API"
  type        = string
}

variable "parent_id" {
  description = "ID of the parent API resource"
  type        = string
}

variable "sfn_role_arn" {
  description = "The Amazon Resource Name (ARN) of the IAM role to use for the state machine"
  type        = string
}

variable "custom_authorizer_id" {
  description = "Custom authorizer id"
  type        = string
}
