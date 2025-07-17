# modulesの変数定義
#（宣言だけ、受取専用）
# リージョン
variable "region" {
  description = "リージョン"
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

# EC2インスタンスタイプ
variable "instance_type" {
  description = "EC2インスタンスタイプ"
  type = string
}

# EC2用キーペア
variable "ec2_key_name" {
  description = "EC2へのSSH接続用キーペア"
  type = string
}