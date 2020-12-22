terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
}

provider "aws" {
  profile             = var.aws_profile
  region              = var.aws_region
  allowed_account_ids = var.aws_allowed_account_ids
}

data "aws_iam_policy_document" "lambda-assume-role-policy" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name               = "${var.app_name}-iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda-assume-role-policy.json

  tags = {
    Application = var.app_name
    Environment = "prod"
  }
}

data "aws_iam_policy_document" "lambda-logging" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "arn:aws:logs:*:*:*"
    ]
  }
}

resource "aws_iam_policy" "lambda-logging" {
  name        = "${var.app_name}-lambda-logging"
  path        = "/"
  description = "IAM policy for logging from a Lambda"
  policy      = data.aws_iam_policy_document.lambda-logging.json
}

resource "aws_iam_role_policy_attachment" "lambda-logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda-logging.arn
}

resource "aws_lambda_function" "api-function" {
  filename      = "../lambda_function.zip"
  function_name = "${var.app_name}_graphql"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "api.default"

  source_code_hash = filebase64sha256("../lambda_function.zip")

  runtime = "nodejs12.x"

  tags = {
    Application = var.app_name
    Environment = "prod"
  }
}

resource "aws_cloudwatch_log_group" "api-function" {
  name              = "/aws/lambda/${var.app_name}_graphql"
  retention_in_days = 14
}

resource "aws_apigatewayv2_api" "api" {
  name          = "${var.app_name}-api"
  protocol_type = "HTTP"

  tags = {
    Application = var.app_name
    Environment = "prod"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "Lambda example"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.api-function.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"

  lifecycle {
    ignore_changes = [passthrough_behavior]
  }
}

resource "aws_apigatewayv2_route" "example" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"
  auto_deploy = true

  lifecycle {
    ignore_changes = [deployment_id, default_route_settings]
  }

  tags = {
    Application = var.app_name
    Environment = "prod"
  }
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api-function.arn
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

output "api_url" {
  value = "${aws_apigatewayv2_api.api.api_endpoint}/${aws_apigatewayv2_stage.prod.id}"
}
