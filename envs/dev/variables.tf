# envsの変数定義
# リージョン
variable "region" {
    description = "リージョン"
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

# EC2インスタンスタイプ
variable "instance_type" {
  description = "EC2インスタンスタイプ"
  default = "t3.micro"
}

# EC2用キーペア
variable "ec2_key_name" {
  description = "EC2へのSSH接続用キーペア"
  default = "tf-aws-key"
}