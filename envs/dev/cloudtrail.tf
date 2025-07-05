# 現在のAWSアカウント情報（アカウントIDなど）を取得するためのデータソース
data "aws_caller_identity" "current" {}

# ローカル変数でバケット名を定義する
locals {
  tf_cloudtrail_bucket_name = "tf-cloudtrail-logs-${data.aws_caller_identity.current.account_id}"
}

# CloudTrailのログを保存するS3バケットを作成
resource "aws_s3_bucket" "tf_cloudtrail_bucket" {
  bucket = local.tf_cloudtrail_bucket_name # バケット名

  force_destroy = true                    # バケットを削除する際、中のオブジェクトも強制的に削除（デフォルト:false）

  tags = {
    Name        = "cloudtrail-logs"       # 名前タグ
    Environment = "dev"                   # 環境タグ（開発用）
  }
}

# 上記S3バケットに対して、パブリックアクセスを完全にブロック
resource "aws_s3_bucket_public_access_block" "tf_cloudtrail_bucket_block" {
  bucket = aws_s3_bucket.tf_cloudtrail_bucket.id  # 対象のS3バケットID

  block_public_acls       = true   # パブリックACLの設定をブロック（デフォルト: false）
  block_public_policy     = true   # パブリックポリシーの設定をブロック（デフォルト: false）
  ignore_public_acls      = true   # パブリックACLを無視（デフォルト: false）
  restrict_public_buckets = true   # パブリックアクセス制限の適用（デフォルト: false）
}

# CloudTrailがS3バケットにログを書き込むためのバケットポリシーを定義
resource "aws_s3_bucket_policy" "tf_cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.tf_cloudtrail_bucket.id  # 対象のS3バケット

  policy = jsonencode({                        # JSON形式でポリシーを記述
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",   # CloudTrailがバケットのACLをチェックするための権限
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com" # CloudTrailサービスに権限を付与
        },
        Action   = "s3:GetBucketAcl",
        Resource = "${aws_s3_bucket.tf_cloudtrail_bucket.arn}"
      },
      {
        Sid       = "AWSCloudTrailWrite",      # CloudTrailがログを書き込むための権限
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action   = "s3:PutObject",             # オブジェクト書き込みの許可
        Resource = "${aws_s3_bucket.tf_cloudtrail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"  # 所有者に完全な権限を付与するACLが必須
          }
        }
      }
    ]
  })
}

# 実際のCloudTrailリソースの作成
resource "aws_cloudtrail" "tf_cloudtrail" {
  depends_on                    = [aws_s3_bucket.tf_cloudtrail_bucket]  # S3バケットが先に作成されることを保証

  name                          = "tf-cloudtrail" # CloudTrail名
  s3_bucket_name                = local.tf_cloudtrail_bucket_name # ログの保存先S3バケット

  include_global_service_events = true  # IAMなどグローバルサービスのイベントも記録対象にする(デフォルト:true)
  is_multi_region_trail         = false  # マルチリージョンでログを収集しない(デフォルト:false)
  enable_log_file_validation    = true  # ログファイルの改ざん検知を有効化(デフォルト:false)
  enable_logging                = true  # CloudTrailのロギングを有効化(デフォルト:true)
  
}