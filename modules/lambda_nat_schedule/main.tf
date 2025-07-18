# Lambda関数のセット
resource "aws_lambda_function" "tf_lambda_nat_scheduler" {
  function_name = "nat-gateway-scheduler"   # Lambda関数名
  filename = "${path.module}/lambda.zip"    # ZIPは事前にindex.jsをZIP化して同ディレクトリに格納しておく
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")  # ZIPファイルの中身に変更あるかをハッシュ値で確認
  handler = "index.handler"                 # Lambdaのエントリポイント
  //runtime = "nodejs18.x"                    # ランタイム（Node.js）ver.18
  runtime = "nodejs20.x"                    # ランタイム（Node.js）.ver20
  role = var.lambda_role_arn                # IAMロール

  timeout = 10

  environment { # Lambdaスクリプト内で参照する変数受け渡し
    variables = {
      NAT_GATEWAY_ID = var.nat_gateway_id   # NAT GatewayのID
      ALLOCATION_ID = var.eip_allocation_id # 割り当て済みEIPのID
      SUBNET_ID = var.subnet_id             # サブネットのID(NAT Gateway作成時にサブネット指定必須)
      ENVIRONMENT = var.environment         # 環境タグ
    }
  }

  tags = {
    Name = "lambda-natgateway-scheduler"    # 管理用の名前
    Description = "NAT Gatewayをスケジュール制御するLambda"
    Environment = var.environment           # 環境タグ
  }
}

# 平日朝 9:00 に起動する EventBridgeルール
resource "aws_cloudwatch_event_rule" "natgateway_start_rule" {
  name                = "natgateway-start-schedule"
  description         = "Start NAT Gateway at 9:00 JST on weekdays"
  schedule_expression = "cron(0 0 ? * MON-FRI *)" # JST 9:00 → UTC 00:00
}

# 平日夜 18:00 に削除する EventBridgeルール
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
}

# Lambda関数へのターゲット設定（削除）
resource "aws_cloudwatch_event_target" "natgateway_stop_target" {
  rule      = aws_cloudwatch_event_rule.natgateway_stop_rule.name
  target_id = "StopLambda"
  arn       = aws_lambda_function.tf_lambda_nat_scheduler.arn

  input = jsonencode({
    action = "stop"
  })
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
