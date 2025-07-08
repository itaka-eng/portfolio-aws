# modulesの変数定義
#（宣言だけ、受取専用）
# リージョン
variable "region" {
  description = "AWS region"
  type = string
}

# CIDR
variable "vpc_cidr" {
  description = "VPCのCIDRブロック"
  type = string
}

# 環境タグ
variable "environment" {
  description = "環境名(dev / prod)"
  type = string
}