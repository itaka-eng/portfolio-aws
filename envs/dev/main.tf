module "vpc" {
    source = "../../modules/vpc"
    # 変数の受け渡し
    region = var.region # リージョン
    vpc_cidr = var.vpc_cidr # VPC CIDR
    
}