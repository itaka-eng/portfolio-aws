resource "aws_vpc" "tf_vpc" {
    cidr_block = var.vpc_cidr
    enable_dns_support = true
    enable_dns_hostnames = true
    
    tags = {
      Name = "tf_vpc"
    }
}

# 公開用Webサーバ用のパブリックサブネット（AZ: 1a）
resource "aws_subnet" "tf_public_a" {
  vpc_id                  = aws_vpc.tf_vpc.id
  cidr_block              = "10.1.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true
  # subnetにはdescription項目なし→tagsに記載

  tags = {
    Name = "public-subnet-a"
    # subnetにはdescription項目なし→tagsに記載
    Description = "公開用Webサーバ用のパブリックサブネット（AZ: 1a）"
  }
}

# 公開用Webサーバ用のパブリックサブネット（AZ: 1c）
resource "aws_subnet" "tf_public_c" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-c"
    Description = "公開用Webサーバ用のパブリックサブネット（AZ: 1c）"
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
  }
}
