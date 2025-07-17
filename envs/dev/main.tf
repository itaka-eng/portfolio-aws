# モジュール呼び出し iam
module "iam" {
    source = "../../modules/iam"
    # 変数の受け渡し
    environment = var.environment   # 環境タグ
}

# モジュール呼び出し vpc
module "vpc" {
    source = "../../modules/vpc"
    # 変数の受け渡し
    region = var.region             # リージョン
    vpc_cidr = var.vpc_cidr         # VPC CIDR
    environment = var.environment   # 環境タグ
    instance_type = var.instance_type   # EC2インスタンスタイプ
    ec2_key_name = var.ec2_key_name # EC2用SSHキーペア
}
# モジュール呼び出し Lambda(NAT Gateway制御用)
module "lambda_nat_schedule" {
    source = "../../modules/lambda_nat_schedule"
    # 変数の受け渡し
    environment = var.environment   # 環境タグ
    lambda_role_arn = module.iam.lambda_role_arn        # Lambda用IAMロールのARN
    eip_allocation_id = module.vpc.eip_allocation_id    # 割当済みEIP(NAT Gateway用)
    nat_gateway_id = module.vpc.nat_gateway_id          # NAT Gateway
    subnet_id = module.vpc.subnet_id                    # パブリックサブネット(1a)
}
