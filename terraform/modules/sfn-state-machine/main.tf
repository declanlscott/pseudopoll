resource "aws_sfn_state_machine" "sfn_state_machine" {
  name       = var.name
  role_arn   = var.role_arn
  definition = var.definition
  type       = var.type

  depends_on = [aws_cloudwatch_log_group.log_group_for_sfn]
}

resource "aws_cloudwatch_log_group" "log_group_for_sfn" {
  name              = "/aws/states/${var.name}"
  retention_in_days = 14
}
