data "aws_iam_policy_document" "api_vote_queue" {
  statement {
    effect = "Allow"

    actions = [
      "sqs:SendMessage",
    ]

    resources = [
      var.vote_queue_arn,
    ]
  }
}

resource "aws_iam_policy" "api_vote_queue" {
  name        = "pseudopoll-api-vote-queue"
  path        = "/"
  description = "IAM policy for API Gateway to send messages to the vote queue"
  policy      = data.aws_iam_policy_document.api_vote_queue.json
}

resource "aws_iam_role_policy_attachment" "api_vote_queue" {
  role       = var.api_role_name
  policy_arn = aws_iam_policy.api_vote_queue.arn
}
