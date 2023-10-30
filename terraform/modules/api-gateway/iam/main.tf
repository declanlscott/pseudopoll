data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "iam_for_apigateway" {
  name               = "iam_for_apigateway"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "apigateway_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:FilterLogEvents"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "apigateway_logging" {
  name        = "apigateway_logging"
  path        = "/"
  description = "IAM policy for logging from API Gateway"
  policy      = data.aws_iam_policy_document.apigateway_logging.json
}

resource "aws_iam_role_policy_attachment" "apigateway_logs" {
  role       = aws_iam_role.iam_for_apigateway.name
  policy_arn = aws_iam_policy.apigateway_logging.arn
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.iam_for_apigateway.arn
}
