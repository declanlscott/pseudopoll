variable "api_id" {
  description = "API identifier"
  type        = string
}

variable "sfn_role_arn" {
  description = "The Amazon Resource Name (ARN) of the IAM role to use for the state machine"
  type        = string
}
