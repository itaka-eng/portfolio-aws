# Lambda関数: NAT Gatewayのスケジュール制御
# - 平日9:00にNAT Gateway作成
# - 平日18:00にNAT Gateway削除
resource "aws_lambda_function" "tf_lambda_nat_scheduler" {
  function_name = "nat-gateway-scheduler"   # Lambda関数名
  filename = "${path.module}/lambda.zip"    # ZIPは事前にindex.jsをZIP化して同ディレクトリに格納しておく
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")  # ZIPファイルの中身に変更あるかをハッシュ値で確認
  handler = "index.handler"                 # Lambdaのエントリポイント
  runtime = "nodejs20.x"                    # ランタイム（Node.js）.ver20
  role = var.lambda_role_arn                # IAMロール
  timeout = 300                             # 最大300秒（5分）まで設定可能
  
  environment { # Lambdaスクリプト内で参照する変数受け渡し
    variables = {
      SUBNET_ID = var.subnet_id             # サブネットのID(NAT Gateway作成時にサブネット指定必須)
      ROUTE_TABLE_ID = var.route_table_id   # プライベートサブネット用のルートテーブルのID
      ENVIRONMENT = var.environment         # 環境タグ
    }
  }

  # DLQ設定（SNSトピック）
  dead_letter_config {
    target_arn = aws_sns_topic.lambda_dlq.arn
  }

  tags = {
    Name = "lambda-natgateway-scheduler"    # 管理用の名前
    Description = "NAT Gatewayをスケジュール制御するLambda"
    Environment = var.environment           # 環境タグ
  }
}

# EventBridgeルール: 平日朝 9:00 に起動する 
resource "aws_cloudwatch_event_rule" "natgateway_start_rule" {
  name                = "natgateway-start-schedule"
  description         = "Start NAT Gateway at 9:00 JST on weekdays"
  schedule_expression = "cron(0 0 ? * MON-FRI *)" # JST 9:00 → UTC 00:00
}

# EventBridgeルール: 平日夜 18:00 に削除する
resource "aws_cloudwatch_event_rule" "natgateway_stop_rule" {
  name                = "natgateway-stop-schedule"
  description         = "Stop NAT Gateway at 18:00 JST on weekdays"
  schedule_expression = "cron(0 9 ? * MON-FRI *)" # JST 18:00 → UTC 9:00
}

# Lambda関数へのターゲット設定（起動）
resource "aws_cloudwatch_event_target" "natgateway_start_target" {
  rule      = aws_cloudwatch_event_rule.natgateway_start_rule.name
  target_id = "StartLambda"
  arn       = aws_lambda_function.tf_lambda_nat_scheduler.arn

  input = jsonencode({
    action = "start"
  })

  # 再試行ポリシーの設定 再試行しないようにする（オプション）
  retry_policy {
    maximum_event_age_in_seconds = 300
    maximum_retry_attempts       = 0
  }
}

# Lambda関数へのターゲット設定（削除）
resource "aws_cloudwatch_event_target" "natgateway_stop_target" {
  rule      = aws_cloudwatch_event_rule.natgateway_stop_rule.name
  target_id = "StopLambda"
  arn       = aws_lambda_function.tf_lambda_nat_scheduler.arn

  input = jsonencode({
    action = "stop"
  })

  # 再試行ポリシーの設定 再試行しないようにする（オプション）
  retry_policy {
    maximum_event_age_in_seconds = 300
    maximum_retry_attempts       = 0
  }
}

# EventBridge から Lambda を実行できるようにする（起動用）
resource "aws_lambda_permission" "allow_eventbridge_start" {
  statement_id  = "AllowExecutionFromEventBridgeStart"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tf_lambda_nat_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.natgateway_start_rule.arn
}

# EventBridge から Lambda を実行できるようにする（削除用）
resource "aws_lambda_permission" "allow_eventbridge_stop" {
  statement_id  = "AllowExecutionFromEventBridgeStop"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tf_lambda_nat_scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.natgateway_stop_rule.arn
}

# SNSトピック（DLQ用）
resource "aws_sns_topic" "lambda_dlq" {
  name = "natgateway-lambda-dlq"
}

# SNSサブスクリプション（メール通知）
resource "aws_sns_topic_subscription" "lambda_dlq_email" {
  topic_arn = aws_sns_topic.lambda_dlq.arn
  protocol  = "email"
  endpoint  = var.dlq_email
}
