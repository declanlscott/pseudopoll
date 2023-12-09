output "resources_hash" {
  value = sha1(jsonencode([
    aws_api_gateway_request_validator.vote,
    aws_api_gateway_method.patch,
    aws_api_gateway_integration.vote,
    aws_api_gateway_integration_response.vote_accepted,
    aws_api_gateway_method_response.patch_accepted,
    aws_api_gateway_method.public_patch,
    aws_api_gateway_integration.public_vote,
    aws_api_gateway_integration_response.public_vote_accepted,
    aws_api_gateway_method_response.public_patch_accepted,
  ]))
}
