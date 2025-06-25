# 任意のプロジェクトでのマルチエージェントシステム利用ガイド

## 概要

Claude Multi-Agent Systemは、任意のプロジェクトにクローンして使用できる汎用的なシステムです。
各Workerが独立したgit worktreeで並列開発を行うことができます。

## セットアップ手順

### 1. システムのクローン

```bash
# 開発したいプロジェクトのディレクトリに移動
cd /path/to/your/project

# claude-multi-agent-systemをサブディレクトリとしてクローン
git clone https://github.com/your-repo/claude-multi-agent-system.git .claude-multi-agent

# または、別の場所にクローンしてPATHを通す
git clone https://github.com/your-repo/claude-multi-agent-system.git ~/tools/claude-multi-agent
export PATH=$PATH:~/tools/claude-multi-agent/scripts
```

### 2. プロジェクト用環境変数の設定

```bash
# プロジェクトルートで実行
export TARGET_PROJECT_ROOT=$(pwd)
export WORKTREE_BASE=$TARGET_PROJECT_ROOT/worktrees

# または、.envファイルを作成
cat > .claude-multi-agent.env << EOF
TARGET_PROJECT_ROOT=$(pwd)
WORKTREE_BASE=$(pwd)/worktrees
EOF
```

### 3. Worktree環境のセットアップ

```bash
# claude-multi-agent-systemのスクリプトディレクトリから実行
cd .claude-multi-agent/scripts

# tmuxセッションの作成
./setup-multiagent.sh

# AIエージェントの起動
./quick-start-multiagent.sh

# ターゲットプロジェクトでworktreeをセットアップ
cd $TARGET_PROJECT_ROOT
$CLAUDE_SYSTEM_PATH/scripts/worktree-manager.sh setup
```

### 4. 開発の開始

```bash
# planlist.mdを作成
vim planlist.md

# Bossコマンダーで配布
.claude-multi-agent/scripts/boss-commander.sh assign

# 各Workerは自分のworktreeで作業
# Worker1: $TARGET_PROJECT_ROOT/worktrees/worker1
# Worker2: $TARGET_PROJECT_ROOT/worktrees/worker2
# Worker3: $TARGET_PROJECT_ROOT/worktrees/worker3
```

## 推奨ディレクトリ構造

```
your-project/
├── .git/                         # プロジェクトのgitリポジトリ
├── .claude-multi-agent/          # クローンしたマルチエージェントシステム
│   ├── scripts/
│   ├── president/
│   ├── boss/
│   └── worker/
├── .claude-multi-agent.env       # プロジェクト固有の環境設定
├── planlist.md                   # プロジェクトの方式案
├── worktrees/                    # 各Workerの作業ディレクトリ
│   ├── worker1/                  # feature/worker-worker1-dev
│   ├── worker2/                  # feature/worker-worker2-dev
│   └── worker3/                  # feature/worker-worker3-dev
└── src/                          # プロジェクトのソースコード
```

## 改善提案

現在のworktree-manager.shを以下のように改善することを推奨します：

```bash
# 現在の実装
PROJECT_ROOT=$(cd "$(dirname "$0")/../.." && pwd)

# 改善案1: 環境変数を優先
PROJECT_ROOT=${TARGET_PROJECT_ROOT:-$(pwd)}

# 改善案2: カレントディレクトリをデフォルトに
PROJECT_ROOT=${TARGET_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}
```

これにより、任意のプロジェクトで柔軟に利用できるようになります。