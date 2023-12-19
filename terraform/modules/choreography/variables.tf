variable "ddb_stream_arn" {
  description = "The ARN of the DynamoDB stream to pipe events from"
  type        = string
}

variable "vote_result_publisher_lambda_function_name" {
  description = "Function name of the vote result publisher lambda"
  type        = string
}

variable "vote_result_publisher_lambda_arn" {
  description = "ARN of the vote result publisher lambda"
  type        = string
}

variable "vote_result_publisher_lambda_alias_name" {
  description = "Alias name of the vote result publisher lambda"
  type        = string
}

variable "vote_count_publisher_lambda_function_name" {
  description = "Function name of the vote publisher lambda"
  type        = string
}

variable "vote_count_publisher_lambda_arn" {
  description = "ARN of the vote publisher lambda"
  type        = string
}

variable "vote_count_publisher_lambda_alias_name" {
  description = "Alias name of the vote publisher lambda"
  type        = string
}

variable "poll_modification_publisher_lambda_function_name" {
  description = "Function name of the poll modification publisher lambda"
  type        = string
}

variable "poll_modification_publisher_lambda_arn" {
  description = "ARN of the poll modification publisher lambda"
  type        = string
}

variable "poll_modification_publisher_lambda_alias_name" {
  description = "Alias name of the poll modification publisher lambda"
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
