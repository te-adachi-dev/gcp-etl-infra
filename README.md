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
