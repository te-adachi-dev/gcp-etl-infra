#!/bin/bash
set -e

echo "=== GCPインフラテスト ==="
echo "日時: $(date '+%Y%m%d_%H%M%S')"

# 変数設定
PROJECT_ID="test0614-353313"
INPUT_BUCKET="dev-input-bucket-20250628"
OUTPUT_BUCKET="dev-output-bucket-20250628"
TEST_FILE="test_$(date '+%Y%m%d_%H%M%S').json"

# テストデータ作成
echo "{\"id\": \"$(date '+%Y%m%d%H%M%S')\", \"data\": {\"type\": \"test\", \"value\": 42}}" > /tmp/${TEST_FILE}

# アップロード
echo "テストファイルをアップロード中..."
gsutil cp /tmp/${TEST_FILE} gs://${INPUT_BUCKET}/

# 処理待機
echo "処理を待機中（10秒）..."
sleep 10

# ログ確認
echo "Cloud Functionのログ："
gcloud functions logs read dev-data-processor --region=asia-northeast1 --limit=10

# 結果確認
echo "処理結果："
gsutil ls -l gs://${OUTPUT_BUCKET}/processed/

# クリーンアップ
rm /tmp/${TEST_FILE}
