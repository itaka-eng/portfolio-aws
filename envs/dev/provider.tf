provider "aws" {
  region  = var.region
  profile = "default"        # aws configure で設定したプロファイル
}
