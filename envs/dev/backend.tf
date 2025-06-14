terraform {
  backend "s3" {
    bucket = "terraform-backend-itakaeng1126"    # 作成したS3バケット名
    key = "dev/terraform.tfstate"
    region = "ap-northeast-1"
    encrypt = true
    dynamodb_table = "terraform-locks"    # 作成したDynamoDBテーブル名
  }
}