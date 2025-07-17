# IAMロール NAT Gateway制御用のLambda実行ロール
resource "aws_iam_role" "tf_role_lambda_natgateway" {
  name = "tf-lambda-natgateway-control-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "sts:AssumeRole"
        ],
        "Principal": {
          "Service": [
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  tags = {
    Name        = "lambda-natgateway-role"  # 管理用の名前
    Description = "NAT Gateway制御用のLambda実行ロール"
    Environment = var.environment           # 環境タグ
  }
}

# IAMポリシー NAT Gateway制御用のLambda実行ロール用
resource "aws_iam_policy" "tf_policy_lambda_natgateway" {
  name = "tf-lambda-natgateway-control-policy"
  description = "NAT Gateway制御用のIAMポリシー"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ec2:DescribeNatGateways",    # NAT Gateway 確認
          "ec2:CreateNatGateway",       # NAT Gateway 作成
          "ec2:DeleteNatGateway",       # NAT Gateway 削除
          "ec2:DescribeAddress",        # EIP 取得
          "ec2:AllocateAddress",        # EIP 割当
          "ec2:ReleaseAddress",         # EIP 開放
          "ec2:DescribeSubnets"         # 確認
        ]
        "Resource" = "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:CreateLogGroup",        # ロググループ作成
          "logs:CreateLogStream",       # ログストリーム作成
          "logs:PutLogEvents"           # ログ書き込み
        ]
        "Resource" = "*"
      }
    ]
  })
}

# IAMロールにIAMポリシーをアタッチする
resource "aws_iam_role_policy_attachment" "tf_role_lambda_natgateway_attach" {
  role = aws_iam_role.tf_role_lambda_natgateway.name            # ポリシーを適用するIAMロールの名前(必須)
  policy_arn = aws_iam_policy.tf_policy_lambda_natgateway.arn   # 適用するポリシーのARN(必須)
}