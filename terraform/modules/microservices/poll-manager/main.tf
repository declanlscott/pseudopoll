module "poll_manager_workflow" {
  source   = "../../sfn-state-machine"
  name     = "poll-manager"
  type     = "EXPRESS"
  role_arn = var.sfn_role_arn

  definition = templatefile(
    "${path.module}/templates/workflow-definition.tftpl",
    {
      pollsTable       = aws_dynamodb_table.polls_table.name,
      pollOptionsTable = aws_dynamodb_table.poll_options_table.name
    }
  )
}

module "poll_manager_iam" {
  source        = "./iam"
  sfn_arn       = module.poll_manager_workflow.sfn_arn
  sfn_role_name = var.sfn_role_name
  ddb_table_arns = [
    aws_dynamodb_table.polls_table.arn,
    aws_dynamodb_table.poll_options_table.arn
  ]
}

resource "aws_api_gateway_resource" "polls" {
  rest_api_id = var.rest_api_id
  parent_id   = var.parent_id
  path_part   = "polls"
}

resource "aws_api_gateway_model" "create_poll" {
  rest_api_id  = var.rest_api_id
  name         = "CreatePoll"
  description  = "Create poll schema"
  content_type = "application/json"

  schema = templatefile("${path.module}/templates/create-poll-model.tftpl", {})
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
  integration_http_method = aws_api_gateway_method.post.http_method
  type                    = "AWS"
  uri                     = "arn:aws:apigateway:us-east-2:states:action/StartSyncExecution"
  credentials             = module.poll_manager_iam.credentials_arn

  request_templates = {
    "application/json" = templatefile(
      "${path.module}/templates/create-poll-mapping.tftpl",
      { stateMachineArn = module.poll_manager_workflow.sfn_arn }
    )
  }

  passthrough_behavior = "WHEN_NO_MATCH"
}


resource "aws_api_gateway_integration_response" "create_poll_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_integration.create_poll.http_method
  status_code = aws_api_gateway_method_response.post_ok.status_code
}

resource "aws_api_gateway_model" "poll" {
  rest_api_id  = var.rest_api_id
  name         = "Poll"
  description  = "Poll schema"
  content_type = "application/json"

  schema = templatefile("${path.module}/templates/poll-model.tftpl", {})
}

resource "aws_api_gateway_method_response" "post_ok" {
  rest_api_id = var.rest_api_id
  resource_id = aws_api_gateway_resource.polls.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

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

resource "aws_dynamodb_table" "poll_options_table" {
  name         = "pseudopoll-poll-options"
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
