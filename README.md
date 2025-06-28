# GCP Terraform Infrastructure

## 概要
GCPで動かすレイクtoレイクなETL。
インフラ構成は以下の通り。
安価なサービスを採用し、コストをかけずにETLワークフローを動かすことができる。

## アーキテクチャ

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│   Upload    │────▶│Cloud Storage │────▶│Cloud Function│
│   Files     │     │ (Input)      │     │ (Process)    │
└─────────────┘     └──────────────┘     └──────┬───────┘
                                                 │
                    ┌──────────────┐             ▼
                    │  Workflows   │     ┌──────────────┐
                    │(Orchestrate) │     │Cloud Storage │
                    └──────────────┘     │ (Output)     │
                                        └──────────────┘
                    ┌──────────────┐
                    │   BigQuery   │
                    │ (Data Lake)  │
                    └──────────────┘
```

### コンポーネント
- **Cloud Storage**: 入力/出力データの保存
  - `dev-input-bucket-20250628`: アップロードファイル格納
  - `dev-output-bucket-20250628`: 処理済みファイル格納
- **Cloud Functions**: JSONファイルの自動処理
- **Workflows**: バッチ処理のオーケストレーション
- **BigQuery**: データウェアハウス（データレイク）

## 前提条件

- GCP プロジェクト
- gcloud CLI
- Terraform (>= 1.0)
- GitHub アカウント（CI/CD用）

## セットアップ

### 1. GCP環境準備

```bash
# プロジェクトIDを設定
export PROJECT_ID="<ここにプロジェクトIDを入力>"

# gcloud設定
gcloud auth login
gcloud config set project $PROJECT_ID

# 必要なAPIを有効化
gcloud services enable storage.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable workflows.googleapis.com
gcloud services enable bigquery.googleapis.com
gcloud services enable cloudbuild.googleapis.com
```

### 2. サービスアカウント作成

```bash
# Terraform用サービスアカウント作成
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Service Account"

# 必要な権限を付与
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/editor"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountAdmin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --role="roles/resourcemanager.projectIamAdmin"

# キーファイル作成
gcloud iam service-accounts keys create ~/terraform-key.json \
    --iam-account=terraform-sa@$PROJECT_ID.iam.gserviceaccount.com

# 認証設定
export GOOGLE_APPLICATION_CREDENTIALS=~/terraform-key.json
```

### 3. Terraform実行

```bash
# リポジトリクローン
git clone https://github.com/te-adachi-dev/gcp-etl-infra
cd gcp-terraform-20250628

# 環境変数設定
export PROJECT_ID="<ここにプロジェクトIDを入力>"

# 初期化
cd environments/dev
terraform init

# デプロイ
terraform plan -var="project_id=$PROJECT_ID"
terraform apply -var="project_id=$PROJECT_ID"
```

### 4. GitHub Secrets設定（CI/CD用）

```bash
# GitHub CLIでシークレット設定
gh secret set GCP_PROJECT_ID --body "$PROJECT_ID"
gh secret set GCP_SA_KEY < ~/terraform-key.json
```

## 使い方

### ファイル処理

1. JSONファイルを入力バケットにアップロード：
```bash
# サンプルファイル作成
echo '{"id": "001", "data": {"type": "sample", "value": 100}}' > sample.json

# アップロード
gsutil cp sample.json gs://dev-input-bucket-20250628/
```

2. Cloud Functionが自動的にトリガーされ、処理を実行

3. 処理済みファイルを確認：
```bash
gsutil ls gs://dev-output-bucket-20250628/processed/
gsutil cat gs://dev-output-bucket-20250628/processed/sample.json | jq .
```

### Workflow実行

```bash
# 手動実行
gcloud workflows run dev-data-pipeline --location=asia-northeast1

# 実行状態確認
gcloud workflows executions list dev-data-pipeline \
    --location=asia-northeast1 --limit=5
```

### ログ確認

```bash
# Cloud Functionのログ
gcloud functions logs read dev-data-processor \
    --region=asia-northeast1 --limit=20

# Workflowの実行詳細
EXECUTION_ID=$(gcloud workflows executions list dev-data-pipeline \
    --location=asia-northeast1 --limit=1 --format="value(name)" | cut -d'/' -f8)
gcloud workflows executions describe $EXECUTION_ID \
    --workflow=dev-data-pipeline --location=asia-northeast1
```

## テスト

インフラの動作確認用スクリプト：

```bash
# テストスクリプト実行
./test-infra.sh

# 総合テスト実行
./full-test.sh
```

## CI/CD

- **Pull Request**: `terraform plan`を自動実行
- **mainブランチマージ**: `terraform apply`を自動実行

ワークフロー定義：
- `.github/workflows/terraform-ci.yml`: PR時のチェック
- `.github/workflows/terraform-cd.yml`: デプロイ

## ディレクトリ構成

```
.
├── environments/        # 環境別設定
│   ├── dev/            # 開発環境
│   └── prod/           # 本番環境
├── modules/            # Terraformモジュール
│   ├── bigquery/       # BigQueryリソース
│   ├── functions/      # Cloud Functions
│   ├── storage/        # Cloud Storage
│   └── workflows/      # Workflows
├── .github/            # GitHub Actions
│   └── workflows/
├── main.tf             # ルートモジュール
├── variables.tf        # 変数定義
├── versions.tf         # バージョン制約
└── README.md           # このファイル
```

## トラブルシューティング

### 権限エラーが発生する場合

```bash
# サービスアカウントの権限確認
gcloud projects get-iam-policy $PROJECT_ID \
    --flatten="bindings[].members" \
    --filter="bindings.members:serviceAccount:terraform-sa@$PROJECT_ID.iam.gserviceaccount.com" \
    --format="table(bindings.role)"
```

### Cloud Functionが動作しない場合

```bash
# 関数の状態確認
gcloud functions describe dev-data-processor --region=asia-northeast1

# エラーログ確認
gcloud functions logs read dev-data-processor \
    --region=asia-northeast1 --filter="severity>=ERROR"
```

## 今後の拡張案

- [ ] Cloud Schedulerによる定期実行
- [ ] Pub/Subトリガーの追加
- [ ] Dataflowとの連携
- [ ] Cloud Monitoringアラート設定
- [ ] データ品質チェック機能
- [ ] 本番環境へのデプロイ

## ライセンス

MIT