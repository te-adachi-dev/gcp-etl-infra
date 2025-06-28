#!/bin/bash

set -e

echo "GCP Terraform CI/CD Setup Script"
echo "================================"

# プロジェクトIDの設定
read -p "Enter your GCP Project ID: " PROJECT_ID
export PROJECT_ID

# ディレクトリ構造の作成
echo "Creating directory structure..."
mkdir -p modules/{storage,functions,workflows,bigquery}
mkdir -p environments/{dev,prod}
mkdir -p .github/workflows

# Function用のZIPファイル作成
echo "Creating function deployment package..."
cd modules/functions
zip function-source.zip main.py requirements.txt
cd ../..

# 環境別の設定ファイル作成
echo "Creating environment configurations..."

# Dev環境
cat > environments/dev/terraform.tfvars <<EOF
project_id  = "${PROJECT_ID}"
environment = "dev"
region      = "asia-northeast1"
EOF

# Dev環境のmain.tf
cat > environments/dev/main.tf <<EOF
module "infrastructure" {
  source      = "../../"
  project_id  = var.project_id
  region      = var.region
  environment = var.environment
}
EOF

# Dev環境のvariables.tf
cp variables.tf environments/dev/

# Dev環境のversions.tf  
cp versions.tf environments/dev/

# Prod環境（同様に作成）
cp -r environments/dev/* environments/prod/
sed -i 's/dev/prod/g' environments/prod/terraform.tfvars

# .gitignore作成
cat > .gitignore <<EOF
*.tfstate
*.tfstate.*
.terraform/
*.tfvars
terraform-key.json
*.zip
.DS_Store
EOF

# README作成
cat > README.md <<EOF
# GCP Terraform Infrastructure

## 概要
GCPでデータレイク基盤を構築するTerraformプロジェクト

## アーキテクチャ
- Cloud Storage (入力/出力バケット)
- Cloud Functions (データ処理)
- Workflows (オーケストレーション)
- BigQuery (データウェアハウス)

## セットアップ
1. GCP CLIのインストール
2. サービスアカウントの作成
3. GitHub Secretsの設定
   - GCP_PROJECT_ID
   - GCP_SA_KEY

## デプロイ
Pull Requestでplan、mainブランチへのマージでapply
EOF

echo "Setup complete!"
echo "Next steps:"
echo "1. Initialize git repository: git init"
echo "2. Add GitHub remote: git remote add origin <your-repo-url>"
echo "3. Set GitHub Secrets:"
echo "   - GCP_PROJECT_ID: ${PROJECT_ID}"
echo "   - GCP_SA_KEY: (contents of ~/terraform-key.json)"