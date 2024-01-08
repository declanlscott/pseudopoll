variable "lambda_logging_policy_arn" {
  description = "ARN of the Lambda logging policy"
  type        = string
}

variable "ddb_stream_pipe_event_source" {
  description = "The source name of the DynamoDB stream pipe"
  type        = string
}

variable "ddb_stream_pipe_event_detail_type" {
  description = "The detail type of the DynamoDB stream pipe"
  type        = string
}

variable "vote_failed_source" {
  description = "The source name of the vote failed event"
  type        = string
}

variable "vote_failed_detail_type" {
  description = "The detail type of the vote failed event"
  type        = string
}

variable "region" {
  description = "The region of the AWS account"
  type        = string
}

variable "iot_custom_authorizer_name" {
  description = "The name of the IoT custom authorizer"
  type        = string
}
