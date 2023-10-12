resource "aws_apigatewayv2_route" "route" {
  api_id    = var.api_id
  route_key = var.route_key
  target    = "integrations/${aws_apigatewayv2_integration.integration.id}"
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id              = var.api_id
  credentials_arn     = var.credentials_arn
  integration_type    = "AWS_PROXY"
  integration_subtype = var.integration_subtype

  request_parameters = var.request_parameters
}
