variable "region" {
  description = "Região da AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefixo para nomear recursos AWS"
  type        = string
  default     = "projeto-aws-relatorios"
}

variable "redis_host" {
  description = "Hostname do Redis Cloud"
  type        = string
}

variable "redis_port" {
  description = "Porta do Redis"
  type        = string
  default     = "17111"
}

variable "redis_user" {
  description = "Usuário Redis (geralmente 'default')"
  type        = string
}

variable "redis_password" {
  description = "Senha do Redis"
  type        = string
  sensitive   = true
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB usada para metadados"
  type        = string
  default     = "relatorios"
}

variable "ses_sender_email" {
  description = "E-mail remetente para envio via SES"
  type        = string
}
