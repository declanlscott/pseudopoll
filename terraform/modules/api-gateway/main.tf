resource "aws_api_gateway_rest_api" "rest_api" {
  name = var.name
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.rest_api.id

  triggers = {
    redeployment = join(",", var.redeployment_trigger_hashes)
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "v1" {
  rest_api_id   = aws_api_gateway_rest_api.rest_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id
  stage_name    = "v1"

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.logging.arn
    format = jsonencode({
      requestId              = "$context.requestId",
      extendedRequestId      = "$context.extendedRequestId",
      ip                     = "$context.identity.sourceIp",
      caller                 = "$context.identity.caller",
      user                   = "$context.identity.user",
      requestTime            = "$context.requestTime",
      httpMethod             = "$context.httpMethod",
      resourcePath           = "$context.resourcePath",
      status                 = "$context.status",
      protocol               = "$context.protocol",
      responseLength         = "$context.responseLength",
      errorMessage           = "$context.error.message",
      errorResponseType      = "$context.error.responseType",
      validationErrorMessage = "$context.error.validationErrorString"
    })
  }

  depends_on = [aws_cloudwatch_log_group.logging]
}

resource "aws_api_gateway_base_path_mapping" "mapping" {
  api_id      = aws_api_gateway_rest_api.rest_api.id
  stage_name  = aws_api_gateway_stage.v1.stage_name
  domain_name = var.api_domain_name
}

resource "aws_cloudwatch_log_group" "logging" {
  name              = "/aws/api-gateway/${aws_api_gateway_rest_api.rest_api.id}"
  retention_in_days = 14
}
