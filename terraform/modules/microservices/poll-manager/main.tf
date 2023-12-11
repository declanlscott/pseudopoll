resource "aws_api_gateway_resource" "polls" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = "polls"
}

resource "aws_api_gateway_resource" "poll" {
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.polls.id
  path_part   = "{pollId}"
}

resource "aws_api_gateway_resource" "public" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = "public"
}

resource "aws_api_gateway_resource" "public_polls" {
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.public.id
  path_part   = "polls"
}

resource "aws_api_gateway_resource" "public_poll" {
  rest_api_id = var.rest_api_id
  parent_id   = aws_api_gateway_resource.public_polls.id
  path_part   = "{pollId}"
}

resource "aws_api_gateway_request_validator" "create_poll" {
  name                  = "create-poll-validator"
  rest_api_id           = var.rest_api_id
  validate_request_body = true
}

resource "aws_api_gateway_method" "post" {
  rest_api_id = var.rest_api_id
  http_method = "POST"
  resource_id = aws_api_gateway_resource.polls.id

  authorization = "CUSTOM"
  authorizer_id = var.custom_authorizer_id

  request_validator_id = aws_api_gateway_request_validator.create_poll.id
  request_models = {
    "application/json" = var.create_poll_model_name
  }
}

resource "aws_api_gateway_method_settings" "post" {
  rest_api_id = var.rest_api_id
  stage_name  = var.stage_name
  method_path = "${aws_api_gateway_resource.polls.path_part}/${aws_api_gateway_method.post.http_method}"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "create_poll" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.polls.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.create_poll_lambda.invoke_arn
}

resource "aws_lambda_permission" "create_poll_api_lambda" {
  statement_id  = "PseudoPollAllowCreatePollLambdaExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.create_poll_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.post.http_method}${aws_api_gateway_resource.polls.path}"
}

module "create_poll_lambda_role" {
  source    = "../../lambda/iam"
  role_name = "pseudopoll-create-poll-lambda-role"
}

resource "aws_iam_role_policy_attachment" "create_poll_logging" {
  role       = module.create_poll_lambda_role.role_name
  policy_arn = var.lambda_logging_policy_arn
}

data "aws_iam_policy_document" "create_poll_lambda_ddb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:TransactWriteItems",
      "dynamodb:PutItem"
    ]

    resources = [
      aws_dynamodb_table.polls_table.arn,
      aws_dynamodb_table.options_table.arn
    ]
  }
}

resource "aws_iam_policy" "create_poll_lambda_ddb" {
  name        = "pseudopoll-create-poll-lambda-ddb"
  description = "IAM policy for create poll lambda to write to DynamoDB"
  path        = "/"
  policy      = data.aws_iam_policy_document.create_poll_lambda_ddb.json
}

resource "aws_iam_role_policy_attachment" "create_poll_lambda_ddb" {
  role       = module.create_poll_lambda_role.role_name
  policy_arn = aws_iam_policy.create_poll_lambda_ddb.arn
}

module "create_poll_lambda" {
  source              = "../../lambda"
  function_name       = "pseudopoll-create-poll"
  role_arn            = module.create_poll_lambda_role.role_arn
  archive_source_file = "${path.module}/../../../../backend/lambdas/create-poll/bin/bootstrap"
  archive_output_path = "${path.module}/../../../../backend/lambdas/create-poll/bin/create-poll.zip"

  environment_variables = {
    POLLS_TABLE_NAME   = aws_dynamodb_table.polls_table.name
    OPTIONS_TABLE_NAME = aws_dynamodb_table.options_table.name
    NANOID_ALPHABET    = var.nanoid_alphabet
    NANOID_LENGTH      = "${var.nanoid_length}"
  }
}

resource "aws_api_gateway_method_response" "post_created" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "201"

  response_models = {
    "application/json" = var.poll_model_name
  }
}

resource "aws_api_gateway_method_response" "post_bad_request" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "400"

  response_models = {
    "application/json" = var.error_model_name
  }
}

resource "aws_api_gateway_method_response" "post_internal_server_error" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "500"

  response_models = {
    "application/json" = var.error_model_name
  }
}

resource "aws_api_gateway_request_validator" "archive_poll" {
  name                  = "archive-poll-validator"
  rest_api_id           = var.rest_api_id
  validate_request_body = true
}

resource "aws_api_gateway_method" "delete" {
  rest_api_id = var.rest_api_id
  http_method = "DELETE"
  resource_id = aws_api_gateway_resource.poll.id

  authorization = "CUSTOM"
  authorizer_id = var.custom_authorizer_id
}

resource "aws_api_gateway_method_settings" "delete" {
  rest_api_id = var.rest_api_id
  stage_name  = var.stage_name
  method_path = "${aws_api_gateway_resource.poll.path_part}/${aws_api_gateway_method.delete.http_method}"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "archive_poll" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.poll.id
  http_method             = aws_api_gateway_method.delete.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.archive_poll_lambda.invoke_arn
}

resource "aws_lambda_permission" "archive_poll_api_lambda" {
  statement_id  = "PseudoPollAllowArchivePollLambdaExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.archive_poll_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.delete.http_method}${aws_api_gateway_resource.poll.path}"
}

module "archive_poll_lambda_role" {
  source    = "../../lambda/iam"
  role_name = "pseudopoll-archive-poll-lambda-role"
}

resource "aws_iam_role_policy_attachment" "archive_poll_logging" {
  role       = module.archive_poll_lambda_role.role_name
  policy_arn = var.lambda_logging_policy_arn
}

data "aws_iam_policy_document" "archive_poll_lambda_ddb" {
  statement {
    effect = "Allow"

    actions = ["dynamodb:UpdateItem"]

    resources = [aws_dynamodb_table.polls_table.arn]
  }
}

resource "aws_iam_policy" "archive_poll_lambda_ddb" {
  name        = "pseudopoll-archive-poll-lambda-ddb"
  description = "IAM policy for archive poll lambda to write to DynamoDB"
  path        = "/"
  policy      = data.aws_iam_policy_document.archive_poll_lambda_ddb.json
}

resource "aws_iam_role_policy_attachment" "archive_poll_lambda_ddb" {
  role       = module.archive_poll_lambda_role.role_name
  policy_arn = aws_iam_policy.archive_poll_lambda_ddb.arn
}

module "archive_poll_lambda" {
  source              = "../../lambda"
  function_name       = "pseudopoll-archive-poll"
  role_arn            = module.archive_poll_lambda_role.role_arn
  archive_source_file = "${path.module}/../../../../backend/lambdas/archive-poll/bin/bootstrap"
  archive_output_path = "${path.module}/../../../../backend/lambdas/archive-poll/bin/archive-poll.zip"

  environment_variables = {
    POLLS_TABLE_NAME = aws_dynamodb_table.polls_table.name
  }
}

resource "aws_api_gateway_method_response" "delete_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.poll.id
  http_method = aws_api_gateway_method.delete.http_method
  status_code = "204"
}

resource "aws_api_gateway_method_response" "delete_bad_request" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.poll.id
  http_method = aws_api_gateway_method.delete.http_method
  status_code = "400"

  response_models = {
    "application/json" = var.error_model_name
  }
}

resource "aws_api_gateway_method_response" "delete_internal_server_error" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.poll.id
  http_method = aws_api_gateway_method.delete.http_method
  status_code = "500"

  response_models = {
    "application/json" = var.error_model_name
  }
}

resource "aws_api_gateway_method" "get" {
  rest_api_id = var.rest_api_id
  http_method = "GET"
  resource_id = aws_api_gateway_resource.poll.id

  authorization = "CUSTOM"
  authorizer_id = var.custom_authorizer_id
}

resource "aws_api_gateway_method_settings" "get" {
  rest_api_id = var.rest_api_id
  stage_name  = var.stage_name
  method_path = "${aws_api_gateway_resource.poll.path_part}/${aws_api_gateway_method.get.http_method}"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "get_poll" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.poll.id
  http_method             = aws_api_gateway_method.get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.get_poll_lambda.invoke_arn
}

resource "aws_lambda_permission" "get_poll_api_lambda" {
  statement_id  = "PseudoPollAllowGetPollLambdaExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.get_poll_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.get.http_method}${aws_api_gateway_resource.poll.path}"
}

module "get_poll_lambda_role" {
  source    = "../../lambda/iam"
  role_name = "pseudopoll-get-poll-lambda-role"
}

resource "aws_iam_role_policy_attachment" "get_poll_logging" {
  role       = module.get_poll_lambda_role.role_name
  policy_arn = var.lambda_logging_policy_arn
}

data "aws_iam_policy_document" "get_poll_lambda_ddb" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
    ]

    resources = [
      aws_dynamodb_table.polls_table.arn,
      aws_dynamodb_table.options_table.arn,
      "${aws_dynamodb_table.options_table.arn}/index/${local.poll_id_index_name}"
    ]
  }
}

resource "aws_iam_policy" "get_poll_lambda_ddb" {
  name        = "pseudopoll-get-poll-lambda-ddb"
  description = "IAM policy for get poll lambda to read from DynamoDB"
  path        = "/"
  policy      = data.aws_iam_policy_document.get_poll_lambda_ddb.json
}

resource "aws_iam_role_policy_attachment" "get_poll_lambda_ddb" {
  role       = module.get_poll_lambda_role.role_name
  policy_arn = aws_iam_policy.get_poll_lambda_ddb.arn
}

module "get_poll_lambda" {
  source              = "../../lambda"
  function_name       = "pseudopoll-get-poll"
  role_arn            = module.get_poll_lambda_role.role_arn
  archive_source_file = "${path.module}/../../../../backend/lambdas/get-poll/bin/bootstrap"
  archive_output_path = "${path.module}/../../../../backend/lambdas/get-poll/bin/get-poll.zip"

  environment_variables = {
    POLLS_TABLE_NAME   = aws_dynamodb_table.polls_table.name
    OPTIONS_TABLE_NAME = aws_dynamodb_table.options_table.name
    POLL_ID_INDEX_NAME = local.poll_id_index_name
  }
}

resource "aws_api_gateway_method_response" "get_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.poll.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "200"

  response_models = {
    "application/json" = var.poll_model_name
  }
}

resource "aws_api_gateway_method_response" "get_forbidden" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.poll.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "403"

  response_models = {
    "application/json" = var.error_model_name
  }
}

resource "aws_api_gateway_method_response" "get_internal_server_error" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.poll.id
  http_method = aws_api_gateway_method.get.http_method
  status_code = "500"

  response_models = {
    "application/json" = var.error_model_name
  }
}

resource "aws_api_gateway_method" "public_get" {
  rest_api_id = var.rest_api_id
  http_method = "GET"
  resource_id = aws_api_gateway_resource.public_poll.id

  authorization = "NONE"
}

resource "aws_api_gateway_method_settings" "public_get" {
  rest_api_id = var.rest_api_id
  stage_name  = var.stage_name
  method_path = "${aws_api_gateway_resource.public_poll.path_part}/${aws_api_gateway_method.public_get.http_method}"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "public_get_poll" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.public_poll.id
  http_method             = aws_api_gateway_method.public_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.get_poll_lambda.invoke_arn
}

resource "aws_lambda_permission" "public_get_poll_api_lambda" {
  statement_id  = "PseudoPollAllowPublicGetPollLambdaExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.get_poll_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${var.rest_api_execution_arn}/*/${aws_api_gateway_method.public_get.http_method}${aws_api_gateway_resource.public_poll.path}"
}

resource "aws_api_gateway_method_response" "public_get_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.public_poll.id
  http_method = aws_api_gateway_method.public_get.http_method
  status_code = "200"

  response_models = {
    "application/json" = var.poll_model_name
  }
}

resource "aws_api_gateway_method_response" "public_get_unauthorized" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.public_poll.id
  http_method = aws_api_gateway_method.public_get.http_method
  status_code = "401"

  response_models = {
    "application/json" = var.error_model_name
  }
}

resource "aws_api_gateway_method_response" "public_get_forbidden" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.public_poll.id
  http_method = aws_api_gateway_method.public_get.http_method
  status_code = "403"

  response_models = {
    "application/json" = var.error_model_name
  }
}

resource "aws_api_gateway_method_response" "public_get_internal_server_error" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.public_poll.id
  http_method = aws_api_gateway_method.public_get.http_method
  status_code = "500"

  response_models = {
    "application/json" = var.error_model_name
  }
}

locals {
  user_id_index_name = "UserId-index"
}

resource "aws_dynamodb_table" "polls_table" {
  name         = "pseudopoll-polls"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "PollId"

  global_secondary_index {
    name            = local.user_id_index_name
    hash_key        = "UserId"
    projection_type = "ALL"
  }

  attribute {
    name = "PollId"
    type = "S"
  }

  attribute {
    name = "UserId"
    type = "S"
  }
}

locals {
  poll_id_index_name = "PollId-index"
}

resource "aws_dynamodb_table" "options_table" {
  name         = "pseudopoll-options"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "OptionId"

  global_secondary_index {
    name            = local.poll_id_index_name
    hash_key        = "PollId"
    projection_type = "ALL"
  }

  attribute {
    name = "OptionId"
    type = "S"
  }

  attribute {
    name = "PollId"
    type = "S"
  }
}
