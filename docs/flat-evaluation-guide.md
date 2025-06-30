# Worker成果物フラット評価ガイド

## 概要

このガイドでは、Bossとして複数のWorkerの修正結果を収集し、フラットに評価する機能の使い方を説明します。

## 新機能

### 1. team-composer.sh

#### collect コマンド
Worker成果物を収集します：
```bash
./scripts/team-composer.sh collect
```

収集される情報：
- tmuxペインの出力（各Workerとboss）
- Git状態（status, log, diff）
- 収集レポート（reports/collection_*/collection_report.md）

#### compare コマンド
収集したWorker成果物を比較評価します：
```bash
./scripts/team-composer.sh compare
```

生成される評価：
- 評価マトリックス（8つの評価項目）
- 技術的分析
- 推奨事項
- 比較レポート（reports/comparison_*.md）

### 2. boss-commander.sh

#### evaluate コマンド
全Workerの成果物を評価開始：
```bash
./scripts/boss-commander.sh evaluate
```

#### compare コマンド
複数アプローチを比較分析：
```bash
./scripts/boss-commander.sh compare
```

#### decide コマンド
最適アプローチを選定：
```bash
./scripts/boss-commander.sh decide
```

## 使用手順

### 1. 初期設定
```bash
# プロジェクトのセットアップ
cd /path/to/your/project
export TARGET_PROJECT_ROOT=$(pwd)

# worktreeのセットアップ
./scripts/worktree-manager-improved.sh setup

# tmuxセッションの起動
./scripts/setup-multiagent.sh
./scripts/quick-start-multiagent.sh
```

### 2. タスク分配
```bash
# planlist.mdを分析
./scripts/boss-commander.sh analyze

# Workerにタスクを分配
./scripts/boss-commander.sh assign
```

### 3. 実装フェーズ
各Workerが並行して実装を進めます。

### 4. 評価フェーズ
```bash
# 成果物を収集
./scripts/team-composer.sh collect

# 比較評価を実行
./scripts/team-composer.sh compare

# Bossとして評価を開始
./scripts/boss-commander.sh evaluate

# 最適アプローチを選定
./scripts/boss-commander.sh decide
```

## レポート形式

### 収集レポート
- `reports/collection_YYYYMMDD_HHMMSS/`
  - `collection_report.md`: 収集概要
  - `worker*_output.txt`: tmux出力
  - `worker*_git_*.txt`: Git情報

### 比較レポート
- `reports/comparison_YYYYMMDD_HHMMSS.md`
  - 評価マトリックス
  - 技術的分析
  - 推奨事項

### 決定書
- `reports/decision_YYYYMMDD_HHMMSS.md`
  - 選定結果
  - 選定理由
  - 実装方針

## 評価基準

以下の8つの観点で評価：
1. 実装完了度
2. コード品質
3. テストカバレッジ
4. パフォーマンス
5. 保守性
6. 拡張性
7. ドキュメント
8. セキュリティ

## tmux活用

システムは以下のtmux機能を活用：
- `tmux capture-pane`: ペイン出力の収集
- `tmux send-keys`: メッセージ送信
- `tmux has-session`: セッション確認

## トラブルシューティング

### 収集エラー
```bash
# tmuxセッションの確認
tmux list-sessions

# セッション名の確認（デフォルト: multiagent）
tmux list-panes -t multiagent
```

### worktreeエラー
```bash
# worktreeの状態確認
./scripts/worktree-manager-improved.sh status

# worktreeの再セットアップ
./scripts/worktree-manager-improved.sh setup
```