# envsの変数定義
# リージョン
variable "region" {
    description = "AWS region"
    default = "ap-northeast-1"  # 東京リージョン
}

# CIDR
variable "vpc_cidr" {
    description = "VPCのCIDRブロック"
    default = "10.1.0.0/16"
}

# 環境タグ
variable "environment" {
  description = "環境名(dev / prod)"
  default = "dev"
}