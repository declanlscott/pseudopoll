data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_sfn" {
  name               = "iam_for_sfn"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "sfn_logging" {
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

resource "aws_iam_policy" "sfn_logging" {
  name        = "sfn_logging"
  path        = "/"
  description = "IAM policy for logging from a SFN State Machine"
  policy      = data.aws_iam_policy_document.sfn_logging.json
}

resource "aws_iam_role_policy_attachment" "sfn_logs" {
  role       = aws_iam_role.iam_for_sfn.name
  policy_arn = aws_iam_policy.sfn_logging.arn
}
