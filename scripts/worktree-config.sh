#!/bin/bash

# Worktree Manager with Configuration Support
# 設定ファイルベースのWorktree管理

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Load configuration
load_project_config() {
    # Try to load config using config-manager
    if [ -f "$SCRIPT_DIR/config-manager.sh" ]; then
        source <("$SCRIPT_DIR/config-manager.sh" export 2>/dev/null) || {
            echo -e "${RED}❌ 設定の読み込みに失敗しました${NC}"
            echo -e "${YELLOW}💡 'config-manager.sh init' で設定を初期化してください${NC}"
            exit 1
        }
    else
        echo -e "${RED}❌ config-manager.sh が見つかりません${NC}"
        exit 1
    fi
}

# Show usage
show_usage() {
    echo -e "${CYAN}🌳 Worktree Manager (設定ファイル版)${NC}"
    echo ""
    echo "設定ファイルベースのWorktree管理ツール"
    echo ""
    echo "Usage:"
    echo "  $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}setup${NC}           - 全Workerのworktree環境をセットアップ"
    echo -e "  ${GREEN}create${NC} <worker> - 特定Workerのworktreeを作成"
    echo -e "  ${GREEN}list${NC}            - 現在のworktree一覧を表示"
    echo -e "  ${GREEN}status${NC}          - 各Workerの作業状況を表示"
    echo -e "  ${GREEN}sync${NC}            - 各Workerのブランチを最新化"
    echo -e "  ${GREEN}cleanup${NC}         - 不要なworktreeを削除"
    echo ""
    echo "Prerequisites:"
    echo "  1. config-manager.sh init で設定を初期化"
    echo "  2. プロジェクトルートにGitリポジトリが存在"
    echo ""
}

# Ensure git repo
ensure_git_repo() {
    if [ ! -d "$PROJECT_ROOT" ]; then
        echo -e "${RED}❌ PROJECT_ROOT が存在しません: $PROJECT_ROOT${NC}"
        exit 1
    fi
    
    cd "$PROJECT_ROOT"
    if ! git rev-parse --git-dir >/dev/null 2>&1; then
        echo -e "${RED}❌ PROJECT_ROOT はGitリポジトリではありません${NC}"
        exit 1
    fi
}

# Ensure worktree directory
ensure_worktree_dir() {
    local worktree_path="$PROJECT_ROOT/$WORKTREE_BASE"
    if [ ! -d "$worktree_path" ]; then
        echo -e "${YELLOW}📁 Worktreeディレクトリを作成中: $worktree_path${NC}"
        mkdir -p "$worktree_path"
    fi
}

# Create worker branch
create_worker_branch() {
    local worker=$1
    local branch_name="${BRANCH_PATTERN//\{worker\}/$worker}"
    
    cd "$PROJECT_ROOT"
    echo -e "${BLUE}🌿 ${worker}用ブランチを準備中: $branch_name${NC}"
    
    # Check if branch exists
    if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ ブランチ '$branch_name' は既に存在します${NC}"
    else
        echo -e "${YELLOW}🔄 ブランチ '$branch_name' を作成中...${NC}"
        git checkout -b "$branch_name"
        
        # Push to remote if exists
        if git remote | grep -q origin; then
            echo -e "${YELLOW}📤 リモートにプッシュ中...${NC}"
            git push -u origin "$branch_name" || echo -e "${YELLOW}⚠️  リモートプッシュをスキップ${NC}"
        fi
        
        # Return to main/master
        git checkout main 2>/dev/null || git checkout master
    fi
}

# Create worker worktree
create_worker_worktree() {
    local worker=$1
    local branch_name="${BRANCH_PATTERN//\{worker\}/$worker}"
    local worktree_path="$PROJECT_ROOT/$WORKTREE_BASE/$worker"
    
    echo -e "${BLUE}🏗️  ${worker}のworktreeを作成中...${NC}"
    
    cd "$PROJECT_ROOT"
    
    # Remove existing worktree
    if [ -d "$worktree_path" ]; then
        echo -e "${YELLOW}⚠️  既存のworktreeを削除中...${NC}"
        git worktree remove "$worktree_path" --force 2>/dev/null || true
        rm -rf "$worktree_path" 2>/dev/null || true
    fi
    
    # Create branch
    create_worker_branch "$worker"
    
    # Create worktree
    echo -e "${YELLOW}🌳 Worktreeを作成中: $worktree_path${NC}"
    git worktree add "$worktree_path" "$branch_name"
    
    # Create worker config
    create_worker_config "$worker" "$worktree_path"
    
    echo -e "${GREEN}✅ ${worker}のworktree作成完了${NC}"
}

# Create worker config file
create_worker_config() {
    local worker=$1
    local worktree_path=$2
    local config_file="$worktree_path/.worker-config"
    
    cat > "$config_file" << EOF
# Worker Configuration
WORKER_ID=$worker
WORKER_NAME=$(echo $worker | tr '[:lower:]' '[:upper:]')
BRANCH_NAME=${BRANCH_PATTERN//\{worker\}/$worker}
WORKTREE_PATH=$worktree_path
PROJECT_ROOT=$PROJECT_ROOT
PROJECT_NAME=$PROJECT_NAME
CREATED_AT=$(date)

# Model Configuration
WORKER_MODEL=$WORKER_MODEL

# Role
ROLE="Developer"
FOCUS="Full-stack Development"
EOF

    echo -e "${GREEN}📝 Worker設定ファイル作成: $config_file${NC}"
}

# Setup all workers
setup_all_workers() {
    echo -e "${CYAN}🚀 全Workerのworktree環境をセットアップ中...${NC}"
    echo ""
    
    # Show project info
    echo -e "${WHITE}プロジェクト情報:${NC}"
    echo "  名前: $PROJECT_NAME"
    echo "  ルート: $PROJECT_ROOT"
    echo "  Workers: $WORKER_NAMES"
    echo ""
    
    ensure_git_repo
    ensure_worktree_dir
    
    # Create worktrees for each worker
    for worker in $WORKER_NAMES; do
        echo ""
        echo -e "${WHITE}=== $worker セットアップ ===${NC}"
        create_worker_worktree "$worker"
    done
    
    echo ""
    echo -e "${GREEN}🎉 全Workerのセットアップ完了！${NC}"
    list_worktrees
}

# List worktrees
list_worktrees() {
    echo -e "${CYAN}📋 Worktree一覧${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    echo -e "${WHITE}Git Worktree情報:${NC}"
    git worktree list
    
    echo ""
    echo -e "${WHITE}Worker別ワークスペース:${NC}"
    for worker in $WORKER_NAMES; do
        local worktree_path="$PROJECT_ROOT/$WORKTREE_BASE/$worker"
        local branch_name="${BRANCH_PATTERN//\{worker\}/$worker}"
        
        if [ -d "$worktree_path" ]; then
            echo -e "${GREEN}✅ $worker${NC}"
            echo "   📁 Path: $worktree_path"
            echo "   🌿 Branch: $branch_name"
            echo "   🤖 Model: $WORKER_MODEL"
        else
            echo -e "${RED}❌ $worker${NC} - 未作成"
        fi
    done
}

# Show worker status
show_status() {
    echo -e "${CYAN}📊 各Workerの作業状況${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    for worker in $WORKER_NAMES; do
        local worktree_path="$PROJECT_ROOT/$WORKTREE_BASE/$worker"
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
            
            # Show latest commit
            echo -e "${BLUE}📌 最新コミット:${NC}"
            git log -1 --oneline
            echo ""
        fi
    done
}

# Sync branches
sync_branches() {
    echo -e "${CYAN}🔄 全Workerブランチを同期中...${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    # Fetch latest
    echo -e "${YELLOW}📥 最新の変更を取得中...${NC}"
    git fetch --all
    
    # Sync each worker
    for worker in $WORKER_NAMES; do
        local worktree_path="$PROJECT_ROOT/$WORKTREE_BASE/$worker"
        local branch_name="${BRANCH_PATTERN//\{worker\}/$worker}"
        
        if [ -d "$worktree_path" ]; then
            echo -e "${WHITE}=== $worker の同期 ===${NC}"
            cd "$worktree_path"
            
            # Pull latest changes
            if git remote | grep -q origin; then
                echo -e "${YELLOW}📥 最新を取得: $branch_name${NC}"
                git pull origin "$branch_name" || echo -e "${YELLOW}⚠️  プルをスキップ${NC}"
            fi
            
            echo -e "${GREEN}✅ $worker 同期完了${NC}"
        fi
    done
}

# Cleanup worktrees
cleanup_worktrees() {
    echo -e "${CYAN}🧹 Worktreeのクリーンアップ${NC}"
    echo ""
    
    cd "$PROJECT_ROOT"
    
    # Show current worktrees
    echo -e "${WHITE}現在のWorktree:${NC}"
    git worktree list
    
    echo ""
    echo -e "${YELLOW}⚠️  全てのWorkerのworktreeを削除しますか？ (y/N)${NC}"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        for worker in $WORKER_NAMES; do
            local worktree_path="$PROJECT_ROOT/$WORKTREE_BASE/$worker"
            if [ -d "$worktree_path" ]; then
                echo -e "${YELLOW}🗑️  $worker を削除中...${NC}"
                git worktree remove "$worktree_path" --force 2>/dev/null || true
                rm -rf "$worktree_path" 2>/dev/null || true
            fi
        done
        
        # Prune worktree list
        git worktree prune
        
        echo -e "${GREEN}✅ クリーンアップ完了${NC}"
    else
        echo "キャンセルしました"
    fi
}

# Main logic
# Load configuration first
load_project_config

case "$1" in
    setup)
        setup_all_workers
        ;;
    create)
        if [ -z "$2" ]; then
            echo -e "${RED}❌ Worker名を指定してください${NC}"
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
        show_status
        ;;
    sync)
        sync_branches
        ;;
    cleanup)
        cleanup_worktrees
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        if [ -n "$1" ]; then
            echo -e "${RED}❌ 不明なコマンド: $1${NC}"
            echo ""
        fi
        show_usage
        exit 1
        ;;
esac