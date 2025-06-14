# modulesの変数定義（宣言だけ、受取専用）
# リージョン
variable "region" {
    description = "AWS region"
    type = string
}

# CIDR
variable "vpc_cidr" {
    description = "VPC CIDR block"
    type = string
}