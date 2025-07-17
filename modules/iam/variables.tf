# modulesの変数定義
#（宣言だけ、受取専用）

# 環境タグ
variable "environment" {
  description = "環境名(dev / prod)"
  type = string
}
