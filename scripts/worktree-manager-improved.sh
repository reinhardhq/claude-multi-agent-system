#!/bin/bash

# Git Worktree Manager for Multi-Agent Development
# 各Workerが独立したワークスペースで並列開発するためのシステム
# 任意のプロジェクトで使用可能な改善版

set -e

# プロジェクトルートの設定（改善版）
# 1. 環境変数 TARGET_PROJECT_ROOT が設定されていればそれを使用
# 2. なければ現在のディレクトリのgitルートを探す
# 3. gitリポジトリでなければ現在のディレクトリを使用
if [ -n "$TARGET_PROJECT_ROOT" ]; then
    PROJECT_ROOT="$TARGET_PROJECT_ROOT"
    echo "🎯 Using TARGET_PROJECT_ROOT: $PROJECT_ROOT"
elif git rev-parse --show-toplevel >/dev/null 2>&1; then
    PROJECT_ROOT=$(git rev-parse --show-toplevel)
    echo "📁 Using git repository root: $PROJECT_ROOT"
else
    PROJECT_ROOT=$(pwd)
    echo "📍 Using current directory: $PROJECT_ROOT"
fi

# Worktreeベースディレクトリ
WORKTREE_BASE="${WORKTREE_BASE:-$PROJECT_ROOT/worktrees}"
SESSION_NAME="multiagent"

# Claude Multi-Agent Systemのパス
CLAUDE_SYSTEM_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# プロジェクト情報表示
show_project_info() {
    echo -e "${CYAN}📋 プロジェクト情報${NC}"
    echo -e "  プロジェクトルート: ${WHITE}$PROJECT_ROOT${NC}"
    echo -e "  Worktreeベース: ${WHITE}$WORKTREE_BASE${NC}"
    echo -e "  Gitリポジトリ: ${WHITE}$(cd "$PROJECT_ROOT" && git remote get-url origin 2>/dev/null || echo "ローカルリポジトリ")${NC}"
    echo ""
}

# 使用方法表示
show_usage() {
    echo -e "${CYAN}🌳 Git Worktree Manager (改善版)${NC}"
    echo ""
    echo "任意のプロジェクトで使用可能なWorktree管理ツール"
    echo ""
    echo "使用方法:"
    echo "  $0 <コマンド> [オプション]"
    echo ""
    echo "コマンド:"
    echo -e "  ${GREEN}info${NC}            - プロジェクト情報を表示"
    echo -e "  ${GREEN}setup${NC}           - 全Workerのworktree環境をセットアップ"
    echo -e "  ${GREEN}create${NC} <worker>  - 特定Workerのworktreeを作成"
    echo -e "  ${GREEN}list${NC}            - 現在のworktree一覧を表示"
    echo -e "  ${GREEN}status${NC}          - 各Workerの作業状況を表示"
    echo -e "  ${GREEN}cleanup${NC}         - 不要なworktreeを削除"
    echo -e "  ${GREEN}sync${NC}            - 各Workerのブランチを最新化"
    echo ""
    echo "環境変数:"
    echo "  TARGET_PROJECT_ROOT - ターゲットプロジェクトのルートパス"
    echo "  WORKTREE_BASE      - Worktreeを作成するベースディレクトリ"
    echo ""
    echo "例:"
    echo "  # 特定のプロジェクトで実行"
    echo "  TARGET_PROJECT_ROOT=/path/to/project $0 setup"
    echo ""
    echo "  # 現在のディレクトリのプロジェクトで実行"
    echo "  $0 setup"
    echo ""
}

# プロジェクトのgit初期化確認
ensure_git_repo() {
    cd "$PROJECT_ROOT"
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Gitリポジトリが見つかりません${NC}"
        echo -e "${YELLOW}Gitリポジトリを初期化しますか？ (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            git init
            echo -e "${GREEN}✅ Gitリポジトリを初期化しました${NC}"
        else
            echo -e "${RED}❌ Gitリポジトリが必要です。終了します。${NC}"
            exit 1
        fi
    fi
}

# worktreeディレクトリの作成
ensure_worktree_dir() {
    if [ ! -d "$WORKTREE_BASE" ]; then
        echo -e "${YELLOW}📁 Worktreeディレクトリを作成中...${NC}"
        mkdir -p "$WORKTREE_BASE"
    fi
}

# ブランチの存在確認
branch_exists() {
    local branch_name=$1
    cd "$PROJECT_ROOT"
    git rev-parse --verify "$branch_name" >/dev/null 2>&1
}

# リモートブランチの存在確認
remote_branch_exists() {
    local branch_name=$1
    cd "$PROJECT_ROOT"
    git ls-remote --heads origin "$branch_name" 2>/dev/null | grep -q "$branch_name"
}

# Workerブランチの作成
create_worker_branch() {
    local worker=$1
    local branch_name="feature/worker-${worker}-dev"
    
    cd "$PROJECT_ROOT"
    echo -e "${BLUE}🌿 ${worker}用ブランチを準備中...${NC}"
    
    # 現在のブランチを確認
    current_branch=$(git branch --show-current)
    
    if branch_exists "$branch_name"; then
        echo -e "${GREEN}✅ ブランチ '$branch_name' は既に存在します${NC}"
    else
        echo -e "${YELLOW}🔄 ブランチ '$branch_name' を作成中...${NC}"
        git checkout -b "$branch_name"
        
        # リモートが設定されている場合はプッシュ
        if git remote | grep -q origin; then
            echo -e "${YELLOW}📤 リモートにプッシュ中...${NC}"
            git push -u origin "$branch_name" || echo -e "${YELLOW}⚠️  リモートへのプッシュをスキップ（権限がない可能性）${NC}"
        fi
        
        # 元のブランチに戻る
        git checkout "$current_branch"
    fi
}

# Workerのworktree作成
create_worker_worktree() {
    local worker=$1
    local branch_name="feature/worker-${worker}-dev"
    local worktree_path="$WORKTREE_BASE/$worker"
    
    echo -e "${BLUE}🏗️  ${worker}のworktreeを作成中...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # worktreeが既に存在する場合は削除
    if [ -d "$worktree_path" ]; then
        echo -e "${YELLOW}⚠️  既存のworktreeを削除中...${NC}"
        git worktree remove "$worktree_path" --force 2>/dev/null || true
        rm -rf "$worktree_path" 2>/dev/null || true
    fi
    
    # ブランチの作成
    create_worker_branch "$worker"
    
    # worktreeの作成
    echo -e "${YELLOW}🌳 Worktreeを作成中: $worktree_path${NC}"
    git worktree add "$worktree_path" "$branch_name"
    
    # Worker用設定ファイルの作成
    create_worker_config "$worker" "$worktree_path"
    
    # プロジェクト固有の初期化スクリプトがあれば実行
    if [ -f "$PROJECT_ROOT/.claude-multi-agent-init.sh" ]; then
        echo -e "${YELLOW}🔧 プロジェクト固有の初期化を実行中...${NC}"
        cd "$worktree_path"
        source "$PROJECT_ROOT/.claude-multi-agent-init.sh"
    fi
    
    echo -e "${GREEN}✅ ${worker}のworktree作成完了: $worktree_path${NC}"
}

# Worker用設定ファイルの作成
create_worker_config() {
    local worker=$1
    local worktree_path=$2
    local config_file="$worktree_path/.worker-config"
    
    cat > "$config_file" << EOF
# Worker Configuration
WORKER_ID=$worker
WORKER_NAME=$(echo $worker | tr '[:lower:]' '[:upper:]')
BRANCH_NAME=feature/worker-${worker}-dev
WORKTREE_PATH=$worktree_path
PROJECT_ROOT=$PROJECT_ROOT
CREATED_AT=$(date)

# Generic Role
ROLE="Developer"
FOCUS="Full-stack Development, Flexible Specialization"

# Project Info
PROJECT_NAME=$(basename "$PROJECT_ROOT")
GIT_REMOTE=$(cd "$PROJECT_ROOT" && git remote get-url origin 2>/dev/null || echo "local")
EOF

    echo -e "${GREEN}📝 Worker設定ファイル作成: $config_file${NC}"
}

# 全Workerのセットアップ
setup_all_workers() {
    echo -e "${CYAN}🚀 全Workerのworktree環境をセットアップ中...${NC}"
    echo ""
    
    show_project_info
    ensure_git_repo
    ensure_worktree_dir
    
    # 各Workerのworktree作成
    for worker in worker1 worker2 worker3; do
        echo ""
        echo -e "${WHITE}=== $worker セットアップ ===${NC}"
        create_worker_worktree "$worker"
    done
    
    echo ""
    echo -e "${GREEN}🎉 全Workerのセットアップ完了！${NC}"
    list_worktrees
}

# worktree一覧表示
list_worktrees() {
    echo -e "${CYAN}📋 現在のWorktree一覧${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    echo -e "${WHITE}Git Worktree情報:${NC}"
    git worktree list
    
    echo ""
    echo -e "${WHITE}Worker別ワークスペース:${NC}"
    for worker in worker1 worker2 worker3; do
        local worktree_path="$WORKTREE_BASE/$worker"
        if [ -d "$worktree_path" ]; then
            echo -e "${GREEN}✅ $worker${NC}"
            echo "   📁 Path: $worktree_path"
            echo "   🌿 Branch: feature/worker-${worker}-dev"
            if [ -f "$worktree_path/.worker-config" ]; then
                echo "   👤 Role: $(grep "^ROLE=" "$worktree_path/.worker-config" | cut -d'"' -f2)"
            fi
        else
            echo -e "${RED}❌ $worker${NC} - 未作成"
        fi
    done
}

# メインロジック
case "$1" in
    info)
        show_project_info
        ;;
    setup)
        setup_all_workers
        ;;
    create)
        if [ -z "$2" ]; then
            echo -e "${RED}エラー: Worker名を指定してください${NC}"
            show_usage
            exit 1
        fi
        ensure_git_repo
        ensure_worktree_dir
        create_worker_worktree "$2"
        ;;
    list)
        list_worktrees
        ;;
    status)
        echo -e "${CYAN}📊 各Workerの作業状況${NC}"
        echo ""
        cd "$PROJECT_ROOT"
        for worker in worker1 worker2 worker3; do
            local worktree_path="$WORKTREE_BASE/$worker"
            if [ -d "$worktree_path" ]; then
                echo -e "${WHITE}=== $worker ===${NC}"
                cd "$worktree_path"
                echo -e "${GREEN}🌿 ブランチ:${NC} $(git branch --show-current)"
                if [ -n "$(git status --porcelain)" ]; then
                    echo -e "${YELLOW}📝 変更あり:${NC}"
                    git status --short
                else
                    echo -e "${GREEN}✅ 変更なし（クリーン状態）${NC}"
                fi
                echo ""
            fi
        done
        ;;
    *)
        show_usage
        exit 1
        ;;
esac