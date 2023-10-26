resource "aws_sfn_state_machine" "sfn_state_machine" {
  name       = var.name
  role_arn   = var.role_arn
  definition = var.definition
  type       = var.type

  logging_configuration {
    log_destination        = "${aws_cloudwatch_log_group.log_group_for_sfn.arn}:*"
    include_execution_data = true
    level                  = "ALL"
  }

  depends_on = [aws_cloudwatch_log_group.log_group_for_sfn]
}

resource "aws_cloudwatch_log_group" "log_group_for_sfn" {
  name              = "/aws/states/${var.name}"
  retention_in_days = 14
}
