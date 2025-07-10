provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "relatorios" {
  bucket = "meu-bucket-relatorios"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "request_handler" {
  function_name = "RequestHandler"
  filename      = "../lambda.zip"
  source_code_hash = filebase64sha256("../lambda.zip")
  handler       = "RequestHandler::RequestHandler.Function::FunctionHandler"
  runtime       = "dotnet6"
  role          = aws_iam_role.lambda_exec_role.arn
  timeout       = 30
  memory_size   = 256

  environment {
    variables = {
      REDIS_HOST = "redis-17111.c276.us-east-1-2.ec2.redns.redis-cloud.com"
      REDIS_PORT = "17111"
      BUCKET     = aws_s3_bucket.relatorios.bucket
    }
  }
}
