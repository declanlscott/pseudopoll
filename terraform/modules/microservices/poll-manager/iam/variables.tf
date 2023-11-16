variable "sfn_arn" {
  description = "The ARN of the state machine"
  type        = string
}

variable "sfn_role_name" {
  description = "The name of the IAM role for the state machine"
  type        = string
}

variable "ddb_table_arns" {
  description = "The ARNs of the DynamoDB tables"
  type        = list(string)
}
