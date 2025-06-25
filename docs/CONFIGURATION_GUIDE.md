# Claude Multi-Agent System 設定ガイド

## 概要

Claude Multi-Agent Systemは、設定ファイルベースで任意のプロジェクトに適用できるように設計されています。
このガイドでは、設定ファイルの使い方と各種設定項目について説明します。

## クイックスタート

### 1. 設定の初期化

プロジェクトのルートディレクトリで以下を実行：

```bash
# Claude Multi-Agent Systemのパスを設定
export CLAUDE_SYSTEM_PATH=/path/to/claude-multi-agent-system

# 設定を初期化（対話形式）
$CLAUDE_SYSTEM_PATH/scripts/config-manager.sh init
```

### 2. 設定ファイルの確認

```bash
# 設定内容を表示
$CLAUDE_SYSTEM_PATH/scripts/config-manager.sh show

# 設定を編集
$CLAUDE_SYSTEM_PATH/scripts/config-manager.sh edit
```

### 3. Worktreeのセットアップ

```bash
# 設定を読み込んでWorktreeを作成
$CLAUDE_SYSTEM_PATH/scripts/worktree-config.sh setup
```

## 設定ファイルの構造

設定ファイルは `<project-root>/.claude-multi-agent/project.config` に保存されます。

### 基本設定

```bash
# ===== Project Information =====
PROJECT_NAME="My Awesome Project"           # プロジェクト名
PROJECT_ROOT="/path/to/your/project"        # プロジェクトのルートパス
PROJECT_REPOSITORY="https://github.com/..."  # Gitリポジトリ URL

# ===== Multi-Agent System Paths =====
CLAUDE_SYSTEM_PATH="/path/to/claude-multi-agent-system"  # システムパス
```

### Worktree設定

```bash
# ===== Worktree Configuration =====
WORKTREE_BASE="worktrees"                   # Worktreeベースディレクトリ
BRANCH_PATTERN="feature/{worker}-dev"       # ブランチ名パターン
```

### Worker設定

```bash
# ===== Worker Configuration =====
WORKER_COUNT=3                              # Worker数
WORKER_NAMES="worker1 worker2 worker3"      # Worker名リスト
```

### モデル設定

```bash
# ===== Agent Model Configuration =====
DEFAULT_MODEL="claude-4-sonnet"             # デフォルトモデル
PRESIDENT_MODEL="claude-4-sonnet"           # President用モデル
BOSS_MODEL="claude-4-sonnet"                # Boss用モデル
WORKER_MODEL="claude-4-sonnet"              # Worker用モデル
```

### 開発設定

```bash
# ===== Development Settings =====
AUTO_COMMIT=false                           # 自動コミット
COMMIT_INTERVAL="30m"                       # コミット間隔
PROGRESS_REPORT_INTERVAL="10m"              # 進捗報告間隔
```

## 環境変数の利用

設定を環境変数としてエクスポート：

```bash
# 環境変数をエクスポート
source <($CLAUDE_SYSTEM_PATH/scripts/config-manager.sh export)

# 確認
echo $PROJECT_ROOT
echo $WORKER_NAMES
```

## 高度な使い方

### 複数プロジェクトの管理

```bash
# プロジェクトA
cd /path/to/projectA
$CLAUDE_SYSTEM_PATH/scripts/config-manager.sh init

# プロジェクトB
cd /path/to/projectB
$CLAUDE_SYSTEM_PATH/scripts/config-manager.sh init

# それぞれ独立した設定で動作
```

### カスタムWorker数

```bash
# 5人のWorkerで作業
WORKER_COUNT=5
WORKER_NAMES="alice bob charlie david eve"
```

### カスタムブランチパターン

```bash
# 例1: 日付入りブランチ
BRANCH_PATTERN="feature/{worker}-$(date +%Y%m%d)"

# 例2: プロジェクト名入りブランチ
BRANCH_PATTERN="multiagent/{worker}/${PROJECT_NAME}"
```

## トラブルシューティング

### 設定ファイルが見つからない

```bash
# 設定ファイルの検索パス
1. ./project.config
2. ./.claude-multi-agent/project.config
3. ./config/project.config
4. $CLAUDE_SYSTEM_PATH/config/project.config
5. ~/.claude-multi-agent/project.config
```

### 設定の検証

```bash
# 設定が有効か確認
$CLAUDE_SYSTEM_PATH/scripts/config-manager.sh validate
```

### 環境のリセット

```bash
# Worktreeをクリーンアップ
$CLAUDE_SYSTEM_PATH/scripts/worktree-config.sh cleanup

# 設定を再初期化
rm -rf .claude-multi-agent
$CLAUDE_SYSTEM_PATH/scripts/config-manager.sh init
```

## ベストプラクティス

1. **プロジェクトごとに設定ファイルを作成**
   - 各プロジェクトの `.claude-multi-agent/` に設定を保存
   - Gitで設定を管理（機密情報は除外）

2. **モデルの使い分け**
   - 複雑なタスク: claude-4-sonnet
   - 単純なタスク: claude-3-haiku
   - コスト最適化を考慮

3. **ブランチ戦略**
   - メインブランチからの分岐を明確に
   - 定期的なマージとクリーンアップ

4. **セキュリティ**
   - APIキーは設定ファイルに含めない
   - `.gitignore` に設定ファイルを追加（必要に応じて）

## 設定例

### シンプルなWebアプリ開発

```bash
PROJECT_NAME="simple-todo-app"
WORKER_COUNT=3
BRANCH_PATTERN="feature/todo-{worker}"
DEFAULT_MODEL="claude-3-haiku"
```

### 大規模プロジェクト

```bash
PROJECT_NAME="enterprise-app"
WORKER_COUNT=5
BRANCH_PATTERN="multiagent/{worker}/sprint-$(date +%U)"
DEFAULT_MODEL="claude-4-sonnet"
AUTO_COMMIT=true
COMMIT_INTERVAL="15m"
```

### オープンソースプロジェクト

```bash
PROJECT_NAME="oss-contribution"
WORKER_COUNT=2
BRANCH_PATTERN="contrib/{worker}"
GITHUB_CREATE_PR=true
```