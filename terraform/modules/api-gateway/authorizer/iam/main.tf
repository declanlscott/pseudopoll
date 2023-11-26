data "aws_iam_policy_document" "invocation_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "invocation_role" {
  name               = "api_gateway_authorizer_invocation_role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.invocation_assume_role.json
}

data "aws_iam_policy_document" "invocation_policy" {
  statement {
    effect    = "Allow"
    resources = [var.authorizer_lambda_arn]
    actions   = ["lambda:InvokeFunction"]
  }
}

resource "aws_iam_role_policy" "invocation_policy" {
  name   = "api_gateway_authorizer_invocation_policy"
  role   = aws_iam_role.invocation_role.id
  policy = data.aws_iam_policy_document.invocation_policy.json
}

module "lambda_role" {
  source    = "../../../lambda/iam"
  role_name = "pseudopoll-authorizer-lambda-role"
}

resource "aws_iam_role_policy_attachment" "logging" {
  role       = module.lambda_role.role_name
  policy_arn = var.lambda_logging_policy_arn
}
