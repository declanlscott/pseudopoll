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

resource "aws_iam_role" "poll_manager_api_role" {
  name               = "poll_manager_api_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "api_to_sfn" {
  statement {
    effect = "Allow"

    actions = ["states:StartExecution"]

    resources = [var.sfn_arn]
  }
}

resource "aws_iam_policy" "api_to_sfn" {
  name        = "api_to_sfn"
  path        = "/"
  description = "IAM policy to allow API Gateway to start execution on the poll manager workflow"
  policy      = data.aws_iam_policy_document.api_to_sfn.json
}

resource "aws_iam_role_policy_attachment" "api_to_sfn" {
  role       = aws_iam_role.poll_manager_api_role.name
  policy_arn = aws_iam_policy.api_to_sfn.arn
}
