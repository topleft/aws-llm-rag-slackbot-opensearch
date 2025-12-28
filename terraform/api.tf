resource "aws_api_gateway_rest_api" "api" {
  name        = "topleft_llm_slackbot_api_${var.env}"
  description = "API for the Topleft LLM Slackbot"
}

resource "aws_api_gateway_resource" "slackbot_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "slackbot"
}

resource "aws_api_gateway_method" "slackbot_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.slackbot_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "slackbot_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.slackbot_resource.id
  http_method             = aws_api_gateway_method.slackbot_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = module.lambda_function_llm_handler.lambda_function_invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_method.slackbot_method,
    aws_api_gateway_integration.slackbot_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.api.body,
      aws_api_gateway_resource.slackbot_resource.id,
      aws_api_gateway_method.slackbot_method.id,
      aws_api_gateway_integration.slackbot_integration.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.env
}
