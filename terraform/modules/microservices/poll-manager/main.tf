module "sfn_role" {
  source    = "../../sfn-state-machine/iam"
  role_name = "pseudopoll-poll-manager-sfn-role"
}

module "poll_manager_workflow" {
  source   = "../../sfn-state-machine"
  name     = "poll-manager"
  type     = "EXPRESS"
  role_arn = module.sfn_role.role_arn

  definition = templatefile(
    "${path.module}/templates/workflow.json",
    {
      pollsTable          = aws_dynamodb_table.polls_table.name,
      optionsTable        = aws_dynamodb_table.options_table.name
      createPollLambdaArn = module.create_poll_lambda.arn
    }
  )
}

module "poll_manager_iam" {
  source        = "./iam"
  sfn_arn       = module.poll_manager_workflow.sfn_arn
  sfn_role_name = module.sfn_role.role_name
  ddb_table_arns = [
    aws_dynamodb_table.polls_table.arn,
    aws_dynamodb_table.options_table.arn
  ]
}

resource "aws_api_gateway_resource" "polls" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = "polls"
}

resource "aws_api_gateway_model" "poll" {
  rest_api_id  = var.rest_api_id
  name         = "Poll"
  description  = "Poll schema"
  content_type = "application/json"

  schema = templatefile(
    "${path.module}/templates/models/poll.json",
    { nanoIdLength = var.nanoid_length }
  )
}

resource "aws_api_gateway_model" "create_poll" {
  rest_api_id  = var.rest_api_id
  name         = "CreatePoll"
  description  = "Create poll schema"
  content_type = "application/json"

  schema = templatefile("${path.module}/templates/models/create-poll.json", {})
}

resource "aws_api_gateway_request_validator" "create_poll" {
  name                  = "create-poll-validator"
  rest_api_id           = var.rest_api_id
  validate_request_body = true
}

resource "aws_api_gateway_model" "archive_poll" {
  rest_api_id  = var.rest_api_id
  name         = "ArchivePoll"
  description  = "Archive poll schema"
  content_type = "application/json"

  schema = templatefile(
    "${path.module}/templates/models/archive-poll.json",
    { nanoIdLength = var.nanoid_length }
  )
}

resource "aws_api_gateway_request_validator" "archive_poll" {
  name                  = "archive-poll-validator"
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
    "application/json" = aws_api_gateway_model.create_poll.name
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
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:us-east-2:states:action/StartSyncExecution"
  credentials             = module.poll_manager_iam.credentials_arn

  request_templates = {
    "application/json" = templatefile(
      "${path.module}/templates/mappings/requests/create-poll.vm",
      { stateMachineArn = module.poll_manager_workflow.sfn_arn }
    )
  }

  passthrough_behavior = "WHEN_NO_MATCH"
}

data "aws_iam_policy_document" "create_poll_sfn_lambda" {
  statement {
    effect = "Allow"

    actions = [
      "lambda:InvokeFunction"
    ]

    resources = [
      module.create_poll_lambda.arn
    ]
  }
}

resource "aws_iam_policy" "create_poll_sfn_lambda" {
  name        = "pseudopoll-create-poll-sfn-lambda"
  description = "IAM policy for poll manager step function to invoke create poll lambda"
  path        = "/"
  policy      = data.aws_iam_policy_document.create_poll_sfn_lambda.json
}

resource "aws_iam_role_policy_attachment" "create_poll_sfn_lambda" {
  role       = module.sfn_role.role_name
  policy_arn = aws_iam_policy.create_poll_sfn_lambda.arn
}

module "create_poll_lambda_role" {
  source    = "../../lambda/iam"
  role_name = "pseudopoll-create-poll-lambda-role"
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
    NANOID_LENGTH      = "${var.nanoid_length}"
  }
}

resource "aws_api_gateway_integration_response" "create_poll_created" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_integration.create_poll.http_method
  status_code = aws_api_gateway_method_response.post_created.status_code

  response_templates = {
    "application/json" = templatefile("${path.module}/templates/mappings/responses/success/create-poll.vm", {})
  }
}

resource "aws_api_gateway_method_response" "post_created" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "201"

  response_models = {
    "application/json" = aws_api_gateway_model.poll.name
  }
}

resource "aws_api_gateway_method" "delete" {
  rest_api_id = var.rest_api_id
  http_method = "DELETE"
  resource_id = aws_api_gateway_resource.polls.id

  authorization = "CUSTOM"
  authorizer_id = var.custom_authorizer_id

  request_validator_id = aws_api_gateway_request_validator.archive_poll.id
  request_models = {
    "application/json" = aws_api_gateway_model.archive_poll.name
  }
}

resource "aws_api_gateway_method_settings" "delete" {
  rest_api_id = var.rest_api_id
  stage_name  = var.stage_name
  method_path = "${aws_api_gateway_resource.polls.path_part}/${aws_api_gateway_method.delete.http_method}"

  settings {
    logging_level      = "INFO"
    metrics_enabled    = true
    data_trace_enabled = true
  }
}

resource "aws_api_gateway_integration" "archive_poll" {
  rest_api_id             = var.rest_api_id
  resource_id             = aws_api_gateway_resource.polls.id
  http_method             = aws_api_gateway_method.delete.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:us-east-2:states:action/StartSyncExecution"
  credentials             = module.poll_manager_iam.credentials_arn

  request_templates = {
    "application/json" = templatefile(
      "${path.module}/templates/mappings/requests/archive-poll.vm",
      { stateMachineArn = module.poll_manager_workflow.sfn_arn }
    )
  }

  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_api_gateway_integration_response" "archive_poll_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_integration.archive_poll.http_method
  status_code = aws_api_gateway_method_response.delete_ok.status_code

  response_templates = {
    "application/json" = templatefile("${path.module}/templates/mappings/responses/success/archive-poll.vm", {})
  }
}

resource "aws_api_gateway_method_response" "delete_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_method.delete.http_method
  status_code = 200

  response_models = {
    "application/json" = aws_api_gateway_model.poll.name
  }
}

resource "aws_dynamodb_table" "polls_table" {
  name         = "pseudopoll-polls"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "PollId"

  global_secondary_index {
    name            = "UserId-index"
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

resource "aws_dynamodb_table" "options_table" {
  name         = "pseudopoll-options"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "OptionId"

  global_secondary_index {
    name            = "PollId-index"
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
