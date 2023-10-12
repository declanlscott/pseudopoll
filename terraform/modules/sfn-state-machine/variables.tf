variable "name" {
  description = "The name of the state machine"
  type        = string
}

variable "definition" {
  description = "The Amazon States Language definition of the state machine"
  type        = string
}

variable "role_arn" {
  description = "The Amazon Resource Name (ARN) of the IAM role to use for this state machine"
  type        = string
}
