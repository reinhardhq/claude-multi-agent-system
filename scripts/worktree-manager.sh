#!/bin/bash

# Git Worktree Manager for Multi-Agent Development
# 各Workerが独立したワークスペースで並列開発するためのシステム

set -e

# 設定
PROJECT_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WORKTREE_BASE="$PROJECT_ROOT/worktrees"
SESSION_NAME="multiagent"

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 使用方法表示
show_usage() {
    echo -e "${CYAN}🌳 Git Worktree Manager${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 <コマンド> [オプション]"
    echo ""
    echo "コマンド:"
    echo -e "  ${GREEN}setup${NC}           - 全Workerのworktree環境をセットアップ"
    echo -e "  ${GREEN}create${NC} <worker>  - 特定Workerのworktreeを作成"
    echo -e "  ${GREEN}list${NC}            - 現在のworktree一覧を表示"
    echo -e "  ${GREEN}status${NC}          - 各Workerの作業状況を表示"
    echo -e "  ${GREEN}cleanup${NC}         - 不要なworktreeを削除"
    echo -e "  ${GREEN}sync${NC}            - 各Workerのブランチを最新化"
    echo ""
    echo "Worker指定:"
    echo "  worker1, worker2, worker3"
    echo ""
    echo "例:"
    echo "  $0 setup                    # 全Worker環境セットアップ"
    echo "  $0 create worker1           # Worker1専用worktree作成"
    echo "  $0 status                   # 各Workerの状況確認"
    echo ""
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
    git rev-parse --verify "$branch_name" >/dev/null 2>&1
}

# リモートブランチの存在確認
remote_branch_exists() {
    local branch_name=$1
    git ls-remote --heads origin "$branch_name" | grep -q "$branch_name"
}

# Workerブランチの作成
create_worker_branch() {
    local worker=$1
    local branch_name="feature/worker-${worker}-dev"
    
    echo -e "${BLUE}🌿 ${worker}用ブランチを準備中...${NC}"
    
    # 現在のブランチを確認
    current_branch=$(git branch --show-current)
    
    if branch_exists "$branch_name"; then
        echo -e "${GREEN}✅ ブランチ '$branch_name' は既に存在します${NC}"
    else
        echo -e "${YELLOW}🔄 ブランチ '$branch_name' を作成中...${NC}"
        git checkout -b "$branch_name"
        
        # リモートにプッシュ
        echo -e "${YELLOW}📤 リモートにプッシュ中...${NC}"
        git push -u origin "$branch_name"
        
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
CREATED_AT=$(date)

# Generic Role
ROLE="Developer"
FOCUS="Full-stack Development, Flexible Specialization"
EOF

    echo -e "${GREEN}📝 Worker設定ファイル作成: $config_file${NC}"
}

# 全Workerのセットアップ
setup_all_workers() {
    echo -e "${CYAN}🚀 全Workerのworktree環境をセットアップ中...${NC}"
    
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
    
    if [ ! -d "$WORKTREE_BASE" ]; then
        echo -e "${YELLOW}⚠️  Worktreeディレクトリが存在しません${NC}"
        return
    fi
    
    echo -e "${WHITE}Git Worktree情報:${NC}"
    git worktree list
    echo ""
    
    echo -e "${WHITE}Worker別ワークスペース:${NC}"
    for worker in worker1 worker2 worker3; do
        local worktree_path="$WORKTREE_BASE/$worker"
        if [ -d "$worktree_path" ]; then
            local branch_name=$(cd "$worktree_path" && git branch --show-current)
            local config_file="$worktree_path/.worker-config"
            
            echo -e "${GREEN}✅ $worker${NC}"
            echo -e "   📁 Path: $worktree_path"
            echo -e "   🌿 Branch: $branch_name"
            
            if [ -f "$config_file" ]; then
                local role=$(grep "ROLE=" "$config_file" | cut -d'"' -f2)
                echo -e "   👤 Role: $role"
            fi
        else
            echo -e "${RED}❌ $worker${NC} - Worktreeが存在しません"
        fi
    done
}

# 各Workerの作業状況表示
show_status() {
    echo -e "${CYAN}📊 各Workerの作業状況${NC}"
    echo ""
    
    for worker in worker1 worker2 worker3; do
        local worktree_path="$WORKTREE_BASE/$worker"
        
        echo -e "${WHITE}=== $worker ===${NC}"
        
        if [ ! -d "$worktree_path" ]; then
            echo -e "${RED}❌ Worktreeが存在しません${NC}"
            continue
        fi
        
        cd "$worktree_path"
        
        # ブランチ情報
        local branch_name=$(git branch --show-current)
        echo -e "${GREEN}🌿 ブランチ:${NC} $branch_name"
        
        # 変更状況
        local changes=$(git status --porcelain | wc -l)
        if [ "$changes" -gt 0 ]; then
            echo -e "${YELLOW}📝 変更ファイル数:${NC} $changes"
            git status --short
        else
            echo -e "${GREEN}✅ 変更なし（クリーン状態）${NC}"
        fi
        
        # コミット状況
        local commits_ahead=$(git rev-list --count HEAD ^origin/$branch_name 2>/dev/null || echo "0")
        if [ "$commits_ahead" -gt 0 ]; then
            echo -e "${BLUE}📤 プッシュ待ちコミット:${NC} $commits_ahead"
        fi
        
        echo ""
    done
    
    cd "$PROJECT_ROOT"
}

# 不要なworktreeの削除
cleanup_worktrees() {
    echo -e "${YELLOW}🧹 Worktreeクリーンアップ中...${NC}"
    
    # 孤立したworktreeの削除
    git worktree prune
    
    # Worker worktreeの削除確認
    for worker in worker1 worker2 worker3; do
        local worktree_path="$WORKTREE_BASE/$worker"
        
        if [ -d "$worktree_path" ]; then
            echo -e "${YELLOW}❓ $worker のworktreeを削除しますか？ (y/N)${NC}"
            read -r response
            
            if [[ "$response" =~ ^[Yy]$ ]]; then
                git worktree remove "$worktree_path" --force
                echo -e "${GREEN}✅ $worker のworktree削除完了${NC}"
            fi
        fi
    done
}

# 各Workerブランチの同期
sync_workers() {
    echo -e "${CYAN}🔄 各Workerブランチを同期中...${NC}"
    
    for worker in worker1 worker2 worker3; do
        local worktree_path="$WORKTREE_BASE/$worker"
        local branch_name="feature/worker-${worker}-dev"
        
        echo -e "${WHITE}=== $worker 同期 ===${NC}"
        
        if [ ! -d "$worktree_path" ]; then
            echo -e "${RED}❌ Worktreeが存在しません${NC}"
            continue
        fi
        
        cd "$worktree_path"
        
        # リモートから最新を取得
        echo -e "${YELLOW}📥 リモートから最新情報を取得中...${NC}"
        git fetch origin
        
        # マージまたはリベース
        if git rev-parse --verify "origin/$branch_name" >/dev/null 2>&1; then
            echo -e "${YELLOW}🔄 リモートブランチと同期中...${NC}"
            git merge "origin/$branch_name" --no-edit
        fi
        
        echo -e "${GREEN}✅ $worker 同期完了${NC}"
        echo ""
    done
    
    cd "$PROJECT_ROOT"
}

# メイン処理
main() {
    case "${1:-}" in
        "setup")
            setup_all_workers
            ;;
        "create")
            if [ -z "${2:-}" ]; then
                echo -e "${RED}❌ Workerを指定してください${NC}"
                show_usage
                exit 1
            fi
            ensure_worktree_dir
            create_worker_worktree "$2"
            ;;
        "list")
            list_worktrees
            ;;
        "status")
            show_status
            ;;
        "cleanup")
            cleanup_worktrees
            ;;
        "sync")
            sync_workers
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            echo -e "${RED}❌ 不正なコマンド: ${1:-}${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@" 