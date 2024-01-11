resource "aws_cloudwatch_event_bus" "event_bus" {
  name = "pseudopoll-event-bus"
}

data "aws_caller_identity" "main" {}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pipes.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.main.account_id]
    }
  }
}

resource "aws_iam_role" "pipe" {
  name               = "pseudopoll-ddb-stream-to-event-bus-pipe-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_sqs_queue" "pipe_dlq" {}

data "aws_iam_policy_document" "pipe" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:DescribeStream",
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:ListStreams",
      "sqs:SendMessage",
    ]

    resources = [
      var.ddb_stream_arn,
      aws_sqs_queue.pipe_dlq.arn,
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "events:PutEvents",
    ]

    resources = [aws_cloudwatch_event_bus.event_bus.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role_policy" "pipe" {
  name   = "pseudopoll-ddb-stream-to-event-bus-pipe-role-policy"
  role   = aws_iam_role.pipe.name
  policy = data.aws_iam_policy_document.pipe.json
}

resource "aws_pipes_pipe" "pipe" {
  name        = "pseudopoll-ddb-stream-to-event-bus-pipe"
  description = "A pipe that sends events from a dynamodb stream to an event bus"
  role_arn    = aws_iam_role.pipe.arn
  source      = var.ddb_stream_arn
  target      = aws_cloudwatch_event_bus.event_bus.arn

  source_parameters {
    dynamodb_stream_parameters {
      starting_position = "LATEST"
      batch_size        = 1

      dead_letter_config {
        arn = aws_sqs_queue.pipe_dlq.arn
      }
    }
  }

  target_parameters {
    eventbridge_event_bus_parameters {
      source      = var.ddb_stream_pipe_event_source
      detail_type = var.ddb_stream_pipe_event_detail_type
    }
  }

  depends_on = [aws_iam_role_policy.pipe]
}



resource "aws_cloudwatch_log_group" "events" {
  name              = "/aws/events/pseudopoll"
  retention_in_days = 14
}

resource "aws_cloudwatch_event_rule" "log_events" {
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
  name           = "pseudopoll-log-events"
  description    = "A rule that matches all events from this account on the event bus and sends them to the events log group"
  state          = "DISABLED"

  event_pattern = jsonencode({
    account = [data.aws_caller_identity.main.account_id]
  })
}

resource "aws_cloudwatch_event_target" "log_events" {
  rule           = "pseudopoll-log-events"
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
  arn            = aws_cloudwatch_log_group.events.arn
}

data "aws_iam_policy_document" "log_events" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "delivery.logs.amazonaws.com",
        "events.amazonaws.com",
      ]
    }

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["${aws_cloudwatch_log_group.events.arn}:*"]
  }
}

resource "aws_cloudwatch_log_resource_policy" "log_events" {
  policy_name     = "pseudopoll-log-events"
  policy_document = data.aws_iam_policy_document.log_events.json
}

resource "aws_cloudwatch_event_rule" "vote_succeeded" {
  name           = "pseudopoll-vote-succeeded-event-rule"
  description    = "A rule that matches succeeded vote events from the dynamodb stream pipe and sends them to the publisher microservice"
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name

  event_pattern = jsonencode({
    source      = [{ equals-ignore-case = var.ddb_stream_pipe_event_source }]
    detail-type = [{ equals-ignore-case = var.ddb_stream_pipe_event_detail_type }]
    detail = {
      eventName = [{ equals-ignore-case = "INSERT" }]
      dynamodb = {
        Keys = {
          PK = {
            S = [{ prefix = "voter|" }]
          },
          SK = {
            S = [{ prefix = "poll|" }]
          }
        }
      }
    }
  })
}

resource "aws_lambda_permission" "vote_succeeded" {
  statement_id  = "PseudoPollAllowVoteResultPublisherLambdaExecutionFromVoteSucceededEventRule"
  action        = "lambda:InvokeFunction"
  function_name = var.vote_result_publisher_lambda_function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.vote_succeeded.arn
}

resource "aws_cloudwatch_event_target" "vote_succeeded" {
  rule           = aws_cloudwatch_event_rule.vote_succeeded.name
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
  target_id      = "pseudopoll-vote-succeeded-event-rule-target"
  arn            = var.vote_result_publisher_lambda_arn
}

resource "aws_cloudwatch_event_rule" "vote_failed" {
  name           = "pseudopoll-vote-failed-event-rule"
  description    = "A rule that matches failed vote events from the vote lambda and sends them to the publisher microservice"
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name

  event_pattern = jsonencode({
    source      = [{ equals-ignore-case = var.vote_failed_source }]
    detail-type = [{ equals-ignore-case = var.vote_failed_detail_type }]
  })
}

resource "aws_lambda_permission" "vote_failed" {
  statement_id  = "PseudoPollAllowVoteResultPublisherLambdaExecutionFromVoteFailedEventRule"
  action        = "lambda:InvokeFunction"
  function_name = var.vote_result_publisher_lambda_function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.vote_failed.arn
}

resource "aws_cloudwatch_event_target" "vote_failed" {
  rule           = aws_cloudwatch_event_rule.vote_failed.name
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
  target_id      = "pseudopoll-vote-failed-event-rule-target"
  arn            = var.vote_result_publisher_lambda_arn
}

resource "aws_cloudwatch_event_rule" "vote_counted" {
  name           = "pseudopoll-vote-counted-event-rule"
  description    = "A rule that matches vote counted events from the dynamodb stream pipe and sends them to the publisher microservice"
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name

  event_pattern = jsonencode({
    source      = [{ equals-ignore-case = var.ddb_stream_pipe_event_source }]
    detail-type = [{ equals-ignore-case = var.ddb_stream_pipe_event_detail_type }]
    detail = {
      eventName = [{ equals-ignore-case = "MODIFY" }]
      dynamodb = {
        Keys = {
          PK = {
            S = [{ prefix = "option|" }]
          }
          SK = {
            S = [{ prefix = "option|" }]
          }
        }
      }
    }
  })
}

resource "aws_lambda_permission" "vote_counted" {
  statement_id  = "PseudoPollAllowVotePublisherLambdaExecutionFromVoteCountedEventRule"
  action        = "lambda:InvokeFunction"
  function_name = var.vote_count_publisher_lambda_function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.vote_counted.arn
}

resource "aws_cloudwatch_event_target" "vote_counted" {
  rule           = aws_cloudwatch_event_rule.vote_counted.name
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
  target_id      = "pseudopoll-vote-counted-event-rule-target"
  arn            = var.vote_count_publisher_lambda_arn
}

resource "aws_cloudwatch_event_rule" "poll_modified" {
  name           = "pseudopoll-poll-modified-event-rule"
  description    = "A rule that matches poll modified events from the dynamodb stream pipe and sends them to the publisher microservice"
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name

  event_pattern = jsonencode({
    source      = [{ equals-ignore-case = var.ddb_stream_pipe_event_source }]
    detail-type = [{ equals-ignore-case = var.ddb_stream_pipe_event_detail_type }]
    detail = {
      eventName = [{ equals-ignore-case = "MODIFY" }]
      dynamodb = {
        Keys = {
          PK = {
            S = [{ prefix = "poll|" }]
          }
          SK = {
            S = [{ prefix = "poll|" }]
          }
        }
      }
    }
  })
}

resource "aws_lambda_permission" "poll_modified" {
  statement_id  = "PseudoPollAllowPollModificationPublisherLambdaExecutionFromPollModifiedEventRule"
  action        = "lambda:InvokeFunction"
  function_name = var.poll_modification_publisher_lambda_function_name
  principal     = "events.amazonaws.com"

  source_arn = aws_cloudwatch_event_rule.poll_modified.arn
}

resource "aws_cloudwatch_event_target" "poll_modified" {
  rule           = aws_cloudwatch_event_rule.poll_modified.name
  event_bus_name = aws_cloudwatch_event_bus.event_bus.name
  target_id      = "pseudopoll-poll-modified-event-rule-target"
  arn            = var.poll_modification_publisher_lambda_arn
}
