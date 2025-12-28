resource "aws_lambda_function" "llm_handler" {
  filename         = "../handler.zip"
  function_name    = "topleft_llm_slackbot_lambda_${var.env}"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "handler.main.handler"
  source_code_hash = filebase64sha256("../handler.zip")
  runtime          = "python3.12"
  timeout          = 15

  environment {
    variables = {
      ENV = var.env
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "topleft_llm_slackbot_lambda_exec_role_${var.env}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.llm_handler.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
