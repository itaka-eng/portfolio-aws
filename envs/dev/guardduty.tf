# 現在のアカウント情報を取得（アカウントID取得に使用）
#data "aws_caller_identity" "current" {}    # cloudtrail.tfで定義済みなのでコメントアウト

# GuardDutyを有効化（このリージョンでのみ有効）
resource "aws_guardduty_detector" "tf_guardduty" {
  enable = true  # 必須。GuardDutyを有効化する

  finding_publishing_frequency = "SIX_HOURS"  # 通知頻度: FIFTEEN_MINUTES | ONE_HOUR | SIX_HOURS(デフォルト)

  tags = {
    Name        = "guardduty-detector"
    Environment = "dev"
  }
}

# GuardDutyの結果をCloudWatch Logsなどに送る設定も可能ですが、まずはシンプルな構成に留めています