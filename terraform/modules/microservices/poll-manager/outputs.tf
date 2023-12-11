output "resources_hash" {
  value = sha1(jsonencode([
    aws_api_gateway_resource.polls,
    aws_api_gateway_resource.poll,
    aws_api_gateway_resource.public,
    aws_api_gateway_resource.public_polls,
    aws_api_gateway_resource.public_poll,
    aws_api_gateway_request_validator.create_poll,
    aws_api_gateway_method.post,
    aws_api_gateway_integration.create_poll,
    aws_api_gateway_method_response.post_created,
    aws_api_gateway_method_response.post_bad_request,
    aws_api_gateway_method_response.post_internal_server_error,
    aws_api_gateway_request_validator.archive_poll,
    aws_api_gateway_method.delete,
    aws_api_gateway_integration.archive_poll,
    aws_api_gateway_method_response.delete_ok,
    aws_api_gateway_method_response.delete_bad_request,
    aws_api_gateway_method_response.delete_internal_server_error,
    aws_api_gateway_method.get,
    aws_api_gateway_integration.get_poll,
    aws_api_gateway_method_response.get_ok,
    aws_api_gateway_method_response.get_forbidden,
    aws_api_gateway_method_response.get_internal_server_error,
    aws_api_gateway_method.public_get,
    aws_api_gateway_integration.public_get_poll,
    aws_api_gateway_method_response.public_get_ok,
    aws_api_gateway_method_response.public_get_unauthorized,
    aws_api_gateway_method_response.public_get_forbidden,
    aws_api_gateway_method_response.public_get_internal_server_error,
  ]))
}

output "poll_resource_id" {
  value = aws_api_gateway_resource.poll.id
}

output "public_poll_resource_id" {
  value = aws_api_gateway_resource.public_poll.id
}

output "polls_table_arn" {
  value = aws_dynamodb_table.polls_table.arn
}

output "options_table_arn" {
  value = aws_dynamodb_table.options_table.arn
}
