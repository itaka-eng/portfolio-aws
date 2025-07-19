# modulesの変数定義
#（宣言だけ、受取専用）

# 環境タグ
variable "environment" {
  description = "環境名(dev / prod)"
  type = string
}

# Lanbda用IAMロールのARN
variable "lambda_role_arn" {
    description = "Lanbda用IAMロールのARN"
    type = string
}

# 割当済みEIP(NAT Gateway用)
# variable "eip_allocation_id" {
#   description = "割当済みEIP(NAT Gateway用)"
#   type = string
# }

# NAT Gateway
# variable "nat_gateway_id" {
#   description = "NAT Gateway"
#   type = string
# }

# パブリックサブネット(1a)
variable "subnet_id" {
  description = "パブリックサブネット(1a)"
  type = string
}

# プライベートサブネット用ルートテーブルのID
variable "route_table_id" {
  description = "プライベートサブネット用のルートテーブル"
  type = string
}

# DLQ通知用メールアドレス
variable "dlq_email" {
  description = "DLQ通知用メールアドレス"
  type        = string
}