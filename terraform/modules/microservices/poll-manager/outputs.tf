output "resources_hash" {
  value = sha1(jsonencode([
    aws_api_gateway_resource.polls,
    aws_api_gateway_resource.poll,
    aws_api_gateway_resource.public,
    aws_api_gateway_resource.public_polls,
    aws_api_gateway_resource.public_poll,
    aws_api_gateway_request_validator.create_poll,
    aws_api_gateway_method.create_poll,
    aws_api_gateway_integration.create_poll,
    aws_api_gateway_method_response.create_poll_created,
    aws_api_gateway_method_response.create_poll_bad_request,
    aws_api_gateway_method_response.create_poll_internal_server_error,
    aws_api_gateway_request_validator.archive_poll,
    aws_api_gateway_method.archive_poll,
    aws_api_gateway_integration.archive_poll,
    aws_api_gateway_method_response.archive_poll_ok,
    aws_api_gateway_method_response.archive_poll_bad_request,
    aws_api_gateway_method_response.archive_poll_internal_server_error,
    aws_api_gateway_method.get_poll,
    aws_api_gateway_integration.get_poll,
    aws_api_gateway_method_response.get_poll_ok,
    aws_api_gateway_method_response.get_poll_forbidden,
    aws_api_gateway_method_response.get_poll_internal_server_error,
    aws_api_gateway_request_validator.update_poll_duration,
    aws_api_gateway_method.update_poll_duration,
    aws_api_gateway_integration.update_poll_duration,
    aws_api_gateway_method_response.update_poll_duration_ok,
    aws_api_gateway_method_response.update_poll_duration_bad_request,
    aws_api_gateway_method_response.update_poll_duration_internal_server_error,
    aws_api_gateway_method_response.update_poll_duration_not_found,
    aws_api_gateway_method.my_polls,
    aws_api_gateway_integration.my_polls,
    aws_api_gateway_method_response.my_polls_ok,
    aws_api_gateway_method_response.my_polls_forbidden,
    aws_api_gateway_method_response.my_polls_internal_server_error,
    aws_api_gateway_method.public_get_poll,
    aws_api_gateway_integration.public_get_poll,
    aws_api_gateway_method_response.public_get_poll_ok,
    aws_api_gateway_method_response.public_get_poll_unauthorized,
    aws_api_gateway_method_response.public_get_poll_forbidden,
    aws_api_gateway_method_response.public_get_poll_internal_server_error,
  ]))
}

output "poll_resource_id" {
  value = aws_api_gateway_resource.poll.id
}

output "public_poll_resource_id" {
  value = aws_api_gateway_resource.public_poll.id
}
