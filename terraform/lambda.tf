module "lambda_function_llm_handler" {
  source        = "terraform-aws-modules/lambda/aws"
  version       = "8.1.2"
  function_name = "topleft_llm_slackbot_lambda_${var.env}"
  handler       = "main.handler"
  runtime       = "python3.12"
  source_path   = "../handler"
  publish       = true
  create_role   = true
  environment_variables = {
    ENV = var.env
  }
  allowed_triggers = {
    APIGateway = {
      service    = "apigateway"
      source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
    }
  }
}
