module "lambda_function_llm_handler" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "8.1.2"
  function_name = "topleft_llm_slackbot_lambda_${var.env}"
  handler       = "main.handler"
  runtime       = "python3.12"
  source_path   = "../handler"
  publish       = true
  create_role   = true
  timeout       = 15
  environment_variables = merge(
    {
      ENV                            = var.env
      SLACK_BOT_TOKEN_PARAMETER      = "/topleft/llm_slackbot/${var.env}/SLACK_BOT_TOKEN"
      SLACK_SIGNING_SECRET_PARAMETER = "/topleft/llm_slackbot/${var.env}/SLACK_SIGNING_SECRET"
    },

  )
  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
    }
  }
}

# IAM policy for SSM parameter access
resource "aws_iam_policy" "lambda_ssm_access" {
  name        = "topleft_llm_slackbot_lambda_ssm_access_${var.env}"
  description = "Allow Lambda to access SSM parameters for LLM Slackbot"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:DescribeParameters"
        ]
        Resource = "arn:aws:ssm:*:*:parameter/topleft/llm_slackbot/${var.env}/*"
      }
    ]
  })
}

# Attach SSM policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_ssm_access" {
  role       = module.lambda_function_llm_handler.lambda_role_name
  policy_arn = aws_iam_policy.lambda_ssm_access.arn
}

resource "aws_iam_policy" "lambda_invoke_self" {
  name        = "topleft_llm_slackbot_lambda_invoke_self_${var.env}"
  description = "Allow Lambda to invoke itself for LLM Slackbot"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = module.lambda_function_llm_handler.lambda_function_arn
      }
    ]
  })
}

# Attach invoke self policy to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_invoke_self" {
  role       = module.lambda_function_llm_handler.lambda_role_name
  policy_arn = aws_iam_policy.lambda_invoke_self.arn
}


