# VPC
resource "aws_vpc" "tf_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    
    tags = {
      Name = "tf_vpc" # 管理用の名前
      Description = "Terraform用VPC"
      Environment = var.environment # 環境タグ
    }
}

# 公開用Webサーバ用のパブリックサブネット（AZ: 1a）
resource "aws_subnet" "tf_public_a" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true  # EC2起動時に自動でパブリックIPを付与する(デフォルト:false)
 
  tags = {
    Name = "public-subnet-a"
    Description = "公開用Webサーバ用のパブリックサブネット（AZ: 1a）"
    Environment = var.environment # 環境タグ
  }
}

# 公開用Webサーバ用のパブリックサブネット（AZ: 1c）
resource "aws_subnet" "tf_public_c" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = true  # EC2起動時に自動でパブリックIPを付与する(デフォルト:false)
 
  tags = {
    Name = "public-subnet-c"
    Description = "公開用Webサーバ用のパブリックサブネット（AZ: 1c）"
    Environment = var.environment # 環境タグ
  }
}

# アプリケーション用のプライベートサブネット（AZ: 1a）
resource "aws_subnet" "tf_private_a" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.1.11.0/24"
  availability_zone = "ap-northeast-1a"
 
  tags = {
    Name = "private-subnet-a"
    Description = "アプリケーション用のプライベートサブネット（AZ: 1a）"
    Environment = var.environment # 環境タグ
  }
}

# アプリケーション用のプライベートサブネット（AZ: 1c）
resource "aws_subnet" "tf_private_c" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.1.12.0/24"
  availability_zone = "ap-northeast-1c"
 
  tags = {
    Name = "private-subnet-c"
    Description = "アプリケーション用のプライベートサブネット（AZ: 1c）"
    Environment = var.environment # 環境タグ
  }
}

# Internet Gateway
resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name        = "igw" # 管理用の名前
    Description = "パブリックサブネット用のInternetGateway"
    Environment = var.environment # 環境タグ
  }
}

# NAT Gateway用のElastic IP
# Lambdaで管理する、コメントアウト
# resource "aws_eip" "tf_natgateway_eip" {
#   domain = "vpc"  # VPC向けEIPを指定（オプションだが明示的に付与）

#   tags ={
#     Name = "natgateway-eip" # 管理用の名前
#     Description = "NAT Gateway用のElastic IP(固定グローバルIP)"
#     Environment = var.environment    # 環境タグ
#   }
# }

# NAT Gateway
# Lambdaで管理する、コメントアウト
# resource "aws_nat_gateway" "tf_natgateway" {
#   depends_on = [ aws_internet_gateway.tf_igw ]  # Internet Gatewayを先に作成するよう明示
#   allocation_id = aws_eip.tf_natgateway_eip.id  # NAT Gatewayに関連付けるEIPのID(オプション)
#   subnet_id = aws_subnet.tf_public_a.id         # NAT Gatewayを配置するパブリックサブネット(AZ:1a)(必須)

#   tags = {
#     Name = "nat-gateway"  # 管理用の名前
#     Description = "パブリックサブネット(AZ:1a)に配置されたNAT Gateway"
#     Environment = var.environment # 環境タグ
#   }
# }

# プライベートサブネット用のルートテーブル
resource "aws_route_table" "tf_rttable_private" {
  vpc_id = aws_vpc.tf_vpc.id  # 関連付けるVPCのID(必須)

  tags = {
    Name = "route-table-private"  # 管理用の名前
    Description = "プライベートサブネット用のルートテーブル"
    Environment = var.environment # 環境タグ
  }
}

# ルート設定　プライベートサブネット→NAT Gateway
# Lambdaで管理する、コメントアウト
# resource "aws_route" "tf_route_private2natgateway" {
#   route_table_id = aws_route_table.tf_rttable_private.id  # 対象のルートテーブルのID
#   destination_cidr_block = "0.0.0.0/0"                    # 宛先CIDR(すべて、インターネット向け)
#   nat_gateway_id = aws_nat_gateway.tf_natgateway.id       # 経由するNAT GatewayのID
# }

# ルートテーブルの関連付け　プライベートサブネット用ルートテーブル→プライベートサブネット1a
resource "aws_route_table_association" "tf_rttable_private_1a" {
  subnet_id = aws_subnet.tf_private_a.id                  # 対象のサブネットのID(AZ:1a)
  route_table_id = aws_route_table.tf_rttable_private.id  # 関連付けるルートテーブルのID
}

# ルートテーブルの関連付け　プライベートサブネット用ルートテーブル→プライベートサブネット1c
resource "aws_route_table_association" "tf_rttable_private_1c" {
  subnet_id = aws_subnet.tf_private_c.id                  # 対象のサブネットのID(AZ:1c)
  route_table_id = aws_route_table.tf_rttable_private.id  # 関連付けるルートテーブルのID
}

# セキュリティグループ ALB用
resource "aws_security_group" "tf_alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP and HTTPS traffic from the Internet"
  vpc_id      = aws_vpc.tf_vpc.id

  # インバウンドルール TCP/80をALL許可
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # インバウンドルール TCP/443をALL許可 
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # アウトバウンドルール ALL許可（デフォルト）
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "alb-sg"    # 管理用の名前
    Description = "ALB用セキュリティグループ（HTTP/HTTPS許可）"
    Environment = var.environment # 環境タグ
  }
}

# セキュリティグループ EC2用
resource "aws_security_group" "tf_ec2_sg" {
  name        = "ec2-sg"
  description = "Allow traffic only from ALB SG"
  vpc_id      = aws_vpc.tf_vpc.id

  # インバウンドルール TCP/80をALB用SGから許可
  ingress {
    description = "Allow HTTP only from ALB security group"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.tf_alb_sg.id]
  }

  # アウトバウンドルール ALL許可
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "ec2-sg"        # 管理用の名前
    Description = "EC2用セキュリティグループ（ALBからの通信のみ許可）"
    Environment = var.environment # 環境タグ
  }
}

