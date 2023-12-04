module "authorizer_lambda" {
  source              = "../../lambda"
  function_name       = var.function_name
  role_arn            = module.authorizer_iam.lambda_role_arn
  archive_source_file = var.archive_source_file
  archive_output_path = var.archive_output_path

  environment_variables = {
    JWKS_URI     = var.jwks_uri
    AUDIENCE     = var.audience
    TOKEN_ISSUER = var.token_issuer
  }
}

module "authorizer_iam" {
  source                    = "./iam"
  authorizer_lambda_arn     = module.authorizer_lambda.arn
  lambda_logging_policy_arn = var.lambda_logging_policy_arn
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                             = var.name
  rest_api_id                      = var.rest_api_id
  authorizer_uri                   = module.authorizer_lambda.invoke_arn
  authorizer_credentials           = module.authorizer_iam.invocation_role_arn
  authorizer_result_ttl_in_seconds = 0
}
