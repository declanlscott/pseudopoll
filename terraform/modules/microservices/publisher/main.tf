data "aws_caller_identity" "main" {}

data "aws_iam_policy_document" "lambda_iot_publish" {
  statement {
    effect = "Allow"

    actions = [
      "iot:Connect",
      "iot:Publish"
    ]

    resources = [
      "arn:aws:iot:${var.region}:${data.aws_caller_identity.main.account_id}:topic/*"
    ]
  }
}

resource "aws_iam_policy" "lambda_iot_publish" {
  name        = "pusedopoll-lambda-iot-publish-policy"
  description = "A policy that allows a lambda to publish to an IoT topic"
  policy      = data.aws_iam_policy_document.lambda_iot_publish.json
}

module "vote_result_publisher_lambda_role" {
  source    = "../../lambda/iam"
  role_name = "pseudopoll-vote-result-publisher-lambda-role"
}

resource "aws_iam_role_policy_attachment" "vote_result_publisher_logging" {
  role       = module.vote_result_publisher_lambda_role.role_name
  policy_arn = var.lambda_logging_policy_arn
}

resource "aws_iam_role_policy_attachment" "vote_result_publisher_iot" {
  role       = module.vote_result_publisher_lambda_role.role_name
  policy_arn = aws_iam_policy.lambda_iot_publish.arn
}

module "vote_result_publisher_lambda" {
  source              = "../../lambda"
  function_name       = "pseudopoll-vote-result-publisher"
  role_arn            = module.vote_result_publisher_lambda_role.role_arn
  archive_source_file = "${path.module}/../../../../backend/lambdas/vote-result-publisher/bin/bootstrap"
  archive_output_path = "${path.module}/../../../../backend/lambdas/vote-result-publisher/bin/vote-result-publisher.zip"

  environment_variables = {
    VOTE_SUCCEEDED_SOURCE      = var.ddb_stream_pipe_event_source
    VOTE_SUCCEEDED_DETAIL_TYPE = var.ddb_stream_pipe_event_detail_type
    VOTE_FAILED_SOURCE         = var.vote_failed_source
    VOTE_FAILED_DETAIL_TYPE    = var.vote_failed_detail_type
  }
}

module "vote_count_publisher_lambda_role" {
  source    = "../../lambda/iam"
  role_name = "pseudopoll-vote-count-publisher-lambda-role"
}

resource "aws_iam_role_policy_attachment" "vote_count_publisher_logging" {
  role       = module.vote_count_publisher_lambda_role.role_name
  policy_arn = var.lambda_logging_policy_arn
}

resource "aws_iam_role_policy_attachment" "vote_count_publisher_iot" {
  role       = module.vote_count_publisher_lambda_role.role_name
  policy_arn = aws_iam_policy.lambda_iot_publish.arn
}

module "vote_count_publisher_lambda" {
  source              = "../../lambda"
  function_name       = "pseudopoll-vote-count-publisher"
  role_arn            = module.vote_count_publisher_lambda_role.role_arn
  archive_source_file = "${path.module}/../../../../backend/lambdas/vote-count-publisher/bin/bootstrap"
  archive_output_path = "${path.module}/../../../../backend/lambdas/vote-count-publisher/bin/vote-count-publisher.zip"

  environment_variables = {
    SOURCE      = var.ddb_stream_pipe_event_source
    DETAIL_TYPE = var.ddb_stream_pipe_event_detail_type
  }
}

module "poll_modification_publisher_lambda_role" {
  source    = "../../lambda/iam"
  role_name = "pseudopoll-poll-modification-publisher-lambda-role"
}

resource "aws_iam_role_policy_attachment" "poll_modification_publisher_logging" {
  role       = module.poll_modification_publisher_lambda_role.role_name
  policy_arn = var.lambda_logging_policy_arn
}

resource "aws_iam_role_policy_attachment" "poll_modification_publisher_iot" {
  role       = module.poll_modification_publisher_lambda_role.role_name
  policy_arn = aws_iam_policy.lambda_iot_publish.arn
}

module "poll_modification_publisher_lambda" {
  source              = "../../lambda"
  function_name       = "pseudopoll-poll-modification-publisher"
  role_arn            = module.poll_modification_publisher_lambda_role.role_arn
  archive_source_file = "${path.module}/../../../../backend/lambdas/poll-modification-publisher/bin/bootstrap"
  archive_output_path = "${path.module}/../../../../backend/lambdas/poll-modification-publisher/bin/poll-modification-publisher.zip"

  environment_variables = {
    SOURCE      = var.ddb_stream_pipe_event_source
    DETAIL_TYPE = var.ddb_stream_pipe_event_detail_type
  }
}

module "iot_authorizer_lambda_role" {
  source    = "../../lambda/iam"
  role_name = "pseudopoll-iot-authorizer-lambda-role"
}

module "iot_authorizer_lambda" {
  source              = "../../lambda"
  function_name       = "pseudopoll-iot-authorizer"
  role_arn            = module.iot_authorizer_lambda_role.role_arn
  archive_source_file = "${path.module}/../../../../backend/lambdas/iot-authorizer/bin/bootstrap"
  archive_output_path = "${path.module}/../../../../backend/lambdas/iot-authorizer/bin/iot-authorizer.zip"

  environment_variables = {
    AWS_ACCOUNT_ID = data.aws_caller_identity.main.account_id
  }
}

resource "aws_iot_authorizer" "iot_authorizer" {
  name                    = "pseudopoll-iot-authorizer"
  authorizer_function_arn = module.iot_authorizer_lambda.arn
  signing_disabled        = true
  status                  = "ACTIVE"
}
