output "id" {
  value = aws_api_gateway_authorizer.authorizer.id
}

output "resources_hash" {
  value = sha1(jsonencode([
    aws_api_gateway_authorizer.authorizer
  ]))
}
