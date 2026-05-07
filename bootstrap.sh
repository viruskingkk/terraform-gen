#!/bin/bash
# ============================================================
# bootstrap.sh
# 在執行 terraform init 前，先手動建立 S3 bucket + DynamoDB
# 只需執行一次！
# ============================================================

set -e

REGION="ap-northeast-1"
BUCKET="your-terraform-state-bucket"   # ← 改成你的 bucket 名稱
DYNAMO_TABLE="terraform-state-lock"

echo "=== 建立 S3 State Bucket ==="
aws s3api create-bucket \
  --bucket "$BUCKET" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# 開啟版本控制（State 備份）
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

# 開啟加密
aws s3api put-bucket-encryption \
  --bucket "$BUCKET" \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms"
      }
    }]
  }'

# 封鎖公開存取
aws s3api put-public-access-block \
  --bucket "$BUCKET" \
  --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

echo "=== 建立 DynamoDB State Lock Table ==="
aws dynamodb create-table \
  --table-name "$DYNAMO_TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo ""
echo "✅ Bootstrap 完成！現在可以執行："
echo "   cd terraform"
echo "   terraform init"
