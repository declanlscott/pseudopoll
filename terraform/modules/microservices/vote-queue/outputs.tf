output "resources_hash" {
  value = sha1(jsonencode([
    aws_api_gateway_resource.option,
    aws_api_gateway_method.post,
    aws_api_gateway_integration.vote,
    aws_api_gateway_integration_response.vote_accepted,
    aws_api_gateway_method_response.post_accepted,
    aws_api_gateway_resource.public_option,
    aws_api_gateway_method.public_post,
    aws_api_gateway_integration.public_vote,
    aws_api_gateway_integration_response.public_vote_accepted,
    aws_api_gateway_method_response.public_post_accepted,
  ]))
}
