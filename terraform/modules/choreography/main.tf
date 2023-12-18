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
      detail_type = "DdbStreamEvent"
      source      = "pseudopoll.ddb-stream"
    }
  }

  depends_on = [aws_iam_role_policy.pipe]
}
