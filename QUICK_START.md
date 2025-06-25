# Claude Multi-Agent System - クイックスタートガイド

## 🚀 5分で始める

### ステップ1: 環境セットアップ
```bash
cd claude_multi_agent_system/scripts
./master-controller.sh setup
```

### ステップ2: 4ペイン表示
```bash
tmux attach-session -t multiagent
```

### ステップ3: プレジデントとして指示を出す
```bash
# 別ターミナルで実行
./master-controller.sh send 1 "Hello DEV-A! 最初のタスクを開始してください。"
./master-controller.sh team "全チーム、準備はいかがですか？"
```

## 📋 基本的な使用方法

### プレジデントからの個別指示
```bash
# DEV-Aに指示
./president-controller.sh send 1 "認証システムの設計を開始してください"

# DEV-Bに指示  
./president-controller.sh send 2 "データベース設計をレビューしてください"

# DEV-Cに指示
./president-controller.sh send 3 "フロントエンド統合テストを実施してください"
```

### 全体指示
```bash
./president-controller.sh team "本日の進捗を報告してください"
```

### 進捗報告要求
```bash
./progress-tracker.sh request all standard
```

### 方式案配布
```bash
# 方式案一覧表示
./plan-distributor.sh list

# 全自動配布
./plan-distributor.sh auto
```

## 🎯 よく使うワンライナーコマンド

```bash
# システム状態確認
./master-controller.sh status

# 個別指示（ワンライナー）
./master-controller.sh send 1 "指示内容"

# 全体指示（ワンライナー）  
./master-controller.sh team "指示内容"

# 進捗報告要求（ワンライナー）
./master-controller.sh progress 1 standard

# 方式案配布（ワンライナー）
./master-controller.sh distribute 1 1

# 比較分析（ワンライナー）
./master-controller.sh compare
```

## 📚 詳細ガイド

- [README.md](./README.md) - システム概要と詳細な使用方法
- [WORKFLOW_GUIDE.md](./WORKFLOW_GUIDE.md) - 包括的なワークフローガイド

## 🆘 トラブルシューティング

### tmuxセッションが見つからない
```bash
./setup-multiagent.sh
```

### スクリプトの実行権限がない
```bash
chmod +x scripts/*.sh
```

### システム状態を確認したい
```bash
./master-controller.sh status
```

## 💡 ヒント

1. **まずはマスターコントローラー**: `./master-controller.sh` から始める
2. **ワンライナーモード**: 慣れてきたらワンライナーコマンドで効率化
3. **定期的な進捗確認**: `./progress-tracker.sh request all standard` で定期確認
4. **比較分析の活用**: `./progress-tracker.sh compare` で客観的な分析

さあ、Claude Multi-Agent Systemでチーム開発を始めましょう！ 