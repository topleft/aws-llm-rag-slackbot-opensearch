data "aws_ssm_parameter" "slack_bot_token" {
  name = var.slack_bot_token_parameter
}

data "aws_ssm_parameter" "slack_signing_secret" {
  name = var.slack_signing_secret_parameter
}



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
      ENV                  = var.env
      SLACK_BOT_TOKEN      = data.aws_ssm_parameter.slack_bot_token.value
      SLACK_SIGNING_SECRET = data.aws_ssm_parameter.slack_signing_secret.value
      SLACK_SLASH_COMMAND  = var.slack_slash_command
      KNOWLEDGEBASE_ID     = aws_bedrockagent_knowledge_base.resource_kb.id
      INFERENCE_PROFILE_ID = var.inference_profile_id
    },

  )
  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
    }
  }


}

# IAM role policy for SSM parameter access
resource "aws_iam_role_policy" "lambda_ssm_access" {
  name = "ssm_access"
  role = module.lambda_function_llm_handler.lambda_role_name

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

# IAM role policy for Lambda self-invocation
resource "aws_iam_role_policy" "lambda_invoke_self" {
  name = "invoke_self"
  role = module.lambda_function_llm_handler.lambda_role_name

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

# IAM role policy for Bedrock Knowledge Base access
resource "aws_iam_role_policy" "bedrock_kb_invoke" {
  name = "bedrock_kb_invoke"
  role = module.lambda_function_llm_handler.lambda_role_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "bedrock:RetrieveAndGenerate",
          "bedrock:Retrieve",
          "bedrock:GetInferenceProfile",
          "bedrock:ListInferenceProfiles",
          "bedrock:InvokeModel"
        ]
        Effect = "Allow"
        Resource = [
          aws_bedrockagent_knowledge_base.resource_kb.arn,
          "arn:aws:bedrock:*:*:foundation-model/${var.rag_model_id}",
          "arn:aws:bedrock:*:*:inference-profile/${var.inference_profile_id}",
        ]
      }
    ]
  })
}




