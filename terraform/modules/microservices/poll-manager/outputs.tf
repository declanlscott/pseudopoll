output "resources_hash" {
  value = sha1(jsonencode([
    aws_api_gateway_resource.polls,
    aws_api_gateway_model.create_poll,
    aws_api_gateway_request_validator.create_poll,
    aws_api_gateway_method.post,
    aws_api_gateway_integration.create_poll,
    aws_api_gateway_integration_response.create_poll_ok,
    aws_api_gateway_model.poll,
    aws_api_gateway_method_response.post_ok,
  ]))
}
