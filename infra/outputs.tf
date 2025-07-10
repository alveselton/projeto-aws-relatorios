output "lambda_function_name" {
  description = "Nome da função Lambda principal (RequestHandler)"
  value       = aws_lambda_function.request_handler.function_name
}

output "s3_bucket_name" {
  description = "Nome do bucket S3 onde os PDFs serão armazenados"
  value       = aws_s3_bucket.relatorios.bucket
}

output "api_url_relatorio" {
  description = "URL da API Gateway para o endpoint POST /relatorio"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/prod/relatorio"
}

output "lambda_role_arn" {
  description = "ARN da role associada à Lambda"
  value       = aws_iam_role.lambda_exec_role.arn
}

output "lambda_function_request_handler" {
  description = "Nome da função Lambda principal (RequestHandler)"
  value       = aws_lambda_function.request_handler.function_name
}

output "lambda_function_report_processor" {
  description = "Nome da função Lambda (ReportProcessor)"
  value       = aws_lambda_function.report_processor.function_name
}

output "s3_bucket_name" {
  description = "Nome do bucket S3 onde os PDFs são armazenados"
  value       = aws_s3_bucket.relatorios.bucket
}

output "api_url_relatorio" {
  description = "URL da API Gateway para POST /relatorio"
  value       = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/prod/relatorio"
}

output "lambda_role_arn" {
  description = "ARN da role usada pelas funções Lambda"
  value       = aws_iam_role.lambda_exec_role.arn
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB usada para registrar relatórios processados"
  value       = aws_dynamodb_table.relatorios_table.name
}
