# TerraformでのAWS構築
- 初回にterraform apply  -var="bucket_name=terraform-backend-itakaeng1126" -var="dynamodb_table=terraform-locks"

## 構成図（draw.io）

### 構築対象
- すべて東京リージョンに作成
- VPC
    - CIDR:10.1.0.0/16
- Subnet（Public2つ、Private2つ、マルチAZ）
    - Public Subnet 1A:10.1.1.0/24
    - Public Subnet 1C:10.1.2.0/24
    - Private Subnet 1A:10.1.11.0/24
    - Private Subnet 1C:10.1.12.0/24
- EC2
- RDS（マルチAZ）
- NAT Gateway
- ALB

### セキュリティ対策
- CloudTrail
- GuardDuty
