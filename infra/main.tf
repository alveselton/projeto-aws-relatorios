provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "relatorios" {
  bucket = "${var.project_name}-bucket-relatorios"
  force_destroy = true
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "request_handler" {
  function_name = "${var.project_name}_request_handler"
  handler       = "RequestHandler::RequestHandler.Function::FunctionHandler"
  runtime       = "dotnet8"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 30
  memory_size   = 256

  filename         = "../lambda.zip"
  source_code_hash = filebase64sha256("../lambda.zip")

  environment {
    variables = {
      REDIS_HOST     = var.redis_host
      REDIS_PORT     = var.redis_port
      REDIS_USER     = var.redis_user
      REDIS_PASSWORD = var.redis_password
      S3_BUCKET      = aws_s3_bucket.relatorios.bucket
    }
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project_name}_api"
  description = "API para solicitar relatórios"
}

resource "aws_api_gateway_resource" "relatorio" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "relatorio"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.relatorio.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.relatorio.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.request_handler.invoke_arn
}

resource "aws_lambda_permission" "allow_apigateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.request_handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_function" "report_processor" {
  function_name = "${var.project_name}_report_processor"
  handler       = "ReportProcessor::ReportProcessor.Function::FunctionHandler"
  runtime       = "dotnet8"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 60
  memory_size   = 256

  filename         = "../report_processor.zip"
  source_code_hash = filebase64sha256("../report_processor.zip")

  environment {
    variables = {
      REDIS_HOST       = var.redis_host
      REDIS_PORT       = var.redis_port
      REDIS_USER       = var.redis_user
      REDIS_PASSWORD   = var.redis_password
      S3_BUCKET        = aws_s3_bucket.relatorios.bucket
      DYNAMODB_TABLE   = aws_dynamodb_table.relatorios_table.name
    }
  }
}

resource "aws_dynamodb_table" "relatorios_table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "RelatorioId"

  attribute {
    name = "RelatorioId"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb_access" {
  name = "LambdaDynamoDBAccess"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query"
        ],
        Effect   = "Allow",
        Resource = aws_dynamodb_table.relatorios_table.arn
      }
    ]
  })
}
