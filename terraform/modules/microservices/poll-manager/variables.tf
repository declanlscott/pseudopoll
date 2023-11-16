variable "rest_api_id" {
  description = "ID of the associated REST API"
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

variable "sfn_role_arn" {
  description = "The Amazon Resource Name (ARN) of the IAM role for the state machine"
  type        = string
}

variable "sfn_role_name" {
  description = "The name of the IAM role for the state machine"
  type        = string
}

variable "custom_authorizer_id" {
  description = "Custom authorizer id"
  type        = string
}
