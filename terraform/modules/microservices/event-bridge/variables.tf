variable "bus_name" {
  type        = string
  description = "The name of the event bus"
}

variable "ddb_stream_arn" {
  type        = string
  description = "The ARN of the dynamodb stream"
}
