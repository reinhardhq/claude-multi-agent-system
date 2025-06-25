#!/bin/bash

# Parallel Development Manager - 並列開発統合管理システム
# Git Worktree + Team Composition + Multi-Agent 開発フローの統合管理

set -e

# 設定
PROJECT_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
CLAUDE_SYSTEM_ROOT="$(dirname "$0")/.."
SCRIPT_DIR="$(dirname "$0")"
SESSION_NAME="multiagent"

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
PURPLE='\033[0;35m'
NC='\033[0m'

# 使用方法表示
show_usage() {
    echo -e "${CYAN}🚀 Parallel Development Manager${NC}"
    echo ""
    echo -e "${WHITE}Git Worktree + Team Composition + Multi-Agent 統合管理システム${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 <コマンド> [オプション]"
    echo ""
    echo -e "${GREEN}■ 環境セットアップ${NC}"
    echo -e "  ${GREEN}init${NC}             - 並列開発環境の完全セットアップ"
    echo -e "  ${GREEN}setup${NC}            - Worktree + tmux環境構築"
    echo -e "  ${GREEN}start${NC}            - AIエージェント起動"
    echo ""
    echo -e "${GREEN}■ チーム管理${NC}"
    echo -e "  ${GREEN}assign${NC}           - planlist.mdから自動配布"
    echo -e "  ${GREEN}assign${NC} <方式案>  - 特定方式案を配布"
    echo -e "  ${GREEN}status${NC}           - 全体状況確認"
    echo -e "  ${GREEN}sync${NC}             - 全Workerブランチ同期"
    echo ""
    echo -e "${GREEN}■ 開発フロー${NC}"
    echo -e "  ${GREEN}collect${NC}          - 進捗収集・レポート生成"
    echo -e "  ${GREEN}merge${NC}            - Worker成果物の統合"
    echo -e "  ${GREEN}compare${NC}          - 方式案比較分析"
    echo ""
    echo -e "${GREEN}■ ユーティリティ${NC}"
    echo -e "  ${GREEN}connect${NC}          - tmuxセッションに接続"
    echo -e "  ${GREEN}logs${NC}             - 開発ログ表示"
    echo -e "  ${GREEN}cleanup${NC}          - 環境クリーンアップ"
    echo ""
    echo "例:"
    echo -e "  ${YELLOW}$0 init${NC}                    # 完全セットアップ"
    echo -e "  ${YELLOW}$0 assign${NC}                  # 方式案配布"
    echo -e "  ${YELLOW}$0 status${NC}                  # 状況確認"
    echo -e "  ${YELLOW}$0 connect${NC}                 # tmux接続"
    echo ""
}

# ロゴ表示
show_logo() {
    echo -e "${PURPLE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🚀 PARALLEL DEVELOPMENT MANAGER                            ║
║                                                               ║
║   ┌─────────────────────────────────────────────────────────┐ ║
║   │  👑 PRESIDENT (統括)                                    │ ║
║   └─────────────────────────────────────────────────────────┘ ║
║                              │                               ║
║                              ▼                               ║
║   ┌─────────────────────────────────────────────────────────┐ ║
║   │  🎯 BOSS (チームリーダー)                               │ ║
║   └─────────────────────────────────────────────────────────┘ ║
║                              │                               ║
║              ┌───────────────┼───────────────┐               ║
║              ▼               ▼               ▼               ║
║   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         ║
║   │🎨 WORKER1   │  │⚙️ WORKER2   │  │🧪 WORKER3   │         ║
║   │UI/UX        │  │Backend      │  │Test         │         ║
║   │独立ブランチ  │  │独立ブランチ  │  │独立ブランチ  │         ║
║   └─────────────┘  └─────────────┘  └─────────────┘         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 依存スクリプトの確認
check_dependencies() {
    local missing_scripts=()
    
    if [ ! -f "$SCRIPT_DIR/worktree-manager.sh" ]; then
        missing_scripts+=("worktree-manager.sh")
    fi
    
    if [ ! -f "$SCRIPT_DIR/team-composer.sh" ]; then
        missing_scripts+=("team-composer.sh")
    fi
    
    if [ ! -f "$SCRIPT_DIR/setup-multiagent.sh" ]; then
        missing_scripts+=("setup-multiagent.sh")
    fi
    
    if [ ! -f "$SCRIPT_DIR/quick-start-multiagent.sh" ]; then
        missing_scripts+=("quick-start-multiagent.sh")
    fi
    
    if [ ${#missing_scripts[@]} -gt 0 ]; then
        echo -e "${RED}❌ 必要なスクリプトが見つかりません:${NC}"
        for script in "${missing_scripts[@]}"; do
            echo -e "   - ${RED}$script${NC}"
        done
        exit 1
    fi
}

# 完全セットアップ
init_parallel_dev() {
    show_logo
    echo -e "${CYAN}🚀 並列開発環境の完全セットアップを開始します...${NC}"
    echo ""
    
    # 依存関係確認
    echo -e "${BLUE}📋 依存関係確認中...${NC}"
    check_dependencies
    echo -e "${GREEN}✅ 依存関係OK${NC}"
    echo ""
    
    # Step 1: Git Worktree環境構築
    echo -e "${WHITE}=== Step 1: Git Worktree環境構築 ===${NC}"
    "$SCRIPT_DIR/worktree-manager.sh" setup
    echo ""
    
    # Step 2: tmux環境構築
    echo -e "${WHITE}=== Step 2: tmux環境構築 ===${NC}"
    "$SCRIPT_DIR/setup-multiagent.sh"
    echo ""
    
    # Step 3: planlist.md分析
    echo -e "${WHITE}=== Step 3: planlist.md分析 ===${NC}"
    "$SCRIPT_DIR/team-composer.sh" analyze
    echo ""
    
    # Step 4: 方式案配布
    echo -e "${WHITE}=== Step 4: 方式案配布 ===${NC}"
    "$SCRIPT_DIR/team-composer.sh" assign
    echo ""
    
    # Step 5: メッセージングシステム初期化
    echo -e "${WHITE}=== Step 5: メッセージングシステム初期化 ===${NC}"
    "$SCRIPT_DIR/worktree-message-bridge.sh" init
    echo ""
    
    # Step 6: AIエージェント起動
    echo -e "${WHITE}=== Step 6: AIエージェント起動 ===${NC}"
    "$SCRIPT_DIR/quick-start-multiagent.sh"
    echo ""
    
    # Step 7: tmux-worktree統合設定
    echo -e "${WHITE}=== Step 7: tmux-worktree統合設定 ===${NC}"
    sleep 2  # tmux起動待ち
    "$SCRIPT_DIR/worktree-message-bridge.sh" setup-tmux
    echo ""
    
    # Step 8: 自動同期デーモン開始
    echo -e "${WHITE}=== Step 8: 自動同期デーモン開始 ===${NC}"
    "$SCRIPT_DIR/worktree-message-bridge.sh" start-daemon
    echo ""
    
    echo -e "${GREEN}🎉 並列開発環境セットアップ完了！${NC}"
    echo ""
    echo -e "${YELLOW}次のステップ:${NC}"
    echo -e "  1. ${CYAN}$0 connect${NC} でtmuxセッションに接続"
    echo -e "  2. 各Workerで ASSIGNMENT.md を確認"
    echo -e "  3. 実装開始"
    echo -e "  4. ${CYAN}$0 status${NC} で進捗確認"
    echo ""
}

# 環境セットアップ（AIエージェント起動なし）
setup_environment() {
    echo -e "${CYAN}🔧 環境セットアップ中...${NC}"
    
    check_dependencies
    
    # Worktree環境
    echo -e "${BLUE}📁 Worktree環境構築...${NC}"
    "$SCRIPT_DIR/worktree-manager.sh" setup
    
    # tmux環境
    echo -e "${BLUE}🖥️  tmux環境構築...${NC}"
    "$SCRIPT_DIR/setup-multiagent.sh"
    
    echo -e "${GREEN}✅ 環境セットアップ完了${NC}"
}

# AIエージェント起動
start_agents() {
    echo -e "${CYAN}🤖 AIエージェント起動中...${NC}"
    
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}❌ tmuxセッションが存在しません${NC}"
        echo -e "${YELLOW}💡 先に '$0 setup' を実行してください${NC}"
        exit 1
    fi
    
    "$SCRIPT_DIR/quick-start-multiagent.sh"
    echo -e "${GREEN}✅ AIエージェント起動完了${NC}"
}

# 全体状況確認
show_overall_status() {
    echo -e "${CYAN}📊 全体状況確認${NC}"
    echo ""
    
    # tmuxセッション状況
    echo -e "${WHITE}=== tmuxセッション状況 ===${NC}"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${GREEN}✅ セッション '$SESSION_NAME' 実行中${NC}"
        tmux list-sessions | grep "$SESSION_NAME"
    else
        echo -e "${RED}❌ セッション '$SESSION_NAME' が存在しません${NC}"
    fi
    echo ""
    
    # Worktree状況
    echo -e "${WHITE}=== Worktree状況 ===${NC}"
    "$SCRIPT_DIR/worktree-manager.sh" list
    echo ""
    
    # 配布状況
    echo -e "${WHITE}=== 配布状況 ===${NC}"
    "$SCRIPT_DIR/team-composer.sh" status
    echo ""
    
    # Git状況
    echo -e "${WHITE}=== Git状況 ===${NC}"
    "$SCRIPT_DIR/worktree-manager.sh" status
}

# 全Workerブランチ同期
sync_all_workers() {
    echo -e "${CYAN}🔄 全Workerブランチ同期中...${NC}"
    "$SCRIPT_DIR/worktree-manager.sh" sync
    echo -e "${GREEN}✅ 同期完了${NC}"
}

# 進捗収集
collect_all_progress() {
    echo -e "${CYAN}📥 進捗収集中...${NC}"
    "$SCRIPT_DIR/team-composer.sh" collect
    echo -e "${GREEN}✅ 進捗収集完了${NC}"
}

# Worker成果物の統合
merge_worker_results() {
    echo -e "${CYAN}🔀 Worker成果物統合中...${NC}"
    
    local merge_branch="feature/integrated-results"
    local worktree_base="$PROJECT_ROOT/worktrees"
    
    # 統合ブランチの作成
    cd "$PROJECT_ROOT"
    
    if git branch --list | grep -q "$merge_branch"; then
        echo -e "${YELLOW}⚠️  統合ブランチが既に存在します: $merge_branch${NC}"
        git checkout "$merge_branch"
    else
        echo -e "${BLUE}🌿 統合ブランチを作成: $merge_branch${NC}"
        git checkout -b "$merge_branch"
    fi
    
    # 各Workerの変更をマージ
    for worker in worker1 worker2 worker3; do
        local worker_branch="feature/worker-${worker}-dev"
        local worktree_path="$worktree_base/$worker"
        
        echo -e "${WHITE}=== $worker 統合処理 ===${NC}"
        
        if [ ! -d "$worktree_path" ]; then
            echo -e "${YELLOW}⏳ $worker のworktreeが存在しません${NC}"
            continue
        fi
        
        # Workerブランチの変更を確認
        cd "$worktree_path"
        local changes=$(git status --porcelain | wc -l)
        
        if [ "$changes" -gt 0 ]; then
            echo -e "${BLUE}📝 $worker に未コミットの変更があります${NC}"
            git add .
            git commit -m "Auto-commit before integration: $(date)"
            git push origin "$worker_branch"
        fi
        
        # メインプロジェクトに戻ってマージ
        cd "$PROJECT_ROOT"
        
        echo -e "${BLUE}🔀 $worker_branch をマージ中...${NC}"
        git merge "$worker_branch" --no-edit --allow-unrelated-histories || {
            echo -e "${RED}❌ $worker_branch のマージに失敗しました${NC}"
            echo -e "${YELLOW}💡 手動でコンフリクトを解決してください${NC}"
            continue
        }
        
        echo -e "${GREEN}✅ $worker 統合完了${NC}"
    done
    
    echo ""
    echo -e "${GREEN}🎉 Worker成果物統合完了！${NC}"
    echo -e "${BLUE}📋 統合ブランチ: $merge_branch${NC}"
    
    # 統合レポート生成
    local integration_report="$CLAUDE_SYSTEM_ROOT/reports/integration_report_$(date +%Y%m%d_%H%M%S).md"
    mkdir -p "$(dirname "$integration_report")"
    
    cat > "$integration_report" << EOF
# Worker成果物統合レポート

**統合日時**: $(date)
**統合ブランチ**: $merge_branch
**統合対象**: Worker1, Worker2, Worker3

## 統合結果

$(git log --oneline -10)

## 統合後の変更サマリー

$(git diff --stat HEAD~3)

## 次のステップ

1. 統合後のテスト実行
2. 品質確認
3. デプロイ準備
4. ドキュメント更新

---
*このレポートは自動生成されました*
EOF

    echo -e "${GREEN}📋 統合レポート生成: $integration_report${NC}"
}

# 方式案比較分析
compare_all_approaches() {
    echo -e "${CYAN}📊 方式案比較分析中...${NC}"
    "$SCRIPT_DIR/team-composer.sh" compare
    echo -e "${GREEN}✅ 比較分析完了${NC}"
}

# tmuxセッション接続
connect_session() {
    echo -e "${CYAN}🔗 tmuxセッションに接続中...${NC}"
    
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}❌ セッション '$SESSION_NAME' が存在しません${NC}"
        echo -e "${YELLOW}💡 先に '$0 setup' を実行してください${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ セッション '$SESSION_NAME' に接続します${NC}"
    echo -e "${YELLOW}💡 終了するには Ctrl+B, D を押してください${NC}"
    echo ""
    
    tmux attach-session -t "$SESSION_NAME"
}

# 開発ログ表示
show_logs() {
    echo -e "${CYAN}📋 開発ログ表示${NC}"
    echo ""
    
    local logs_dir="$CLAUDE_SYSTEM_ROOT/logs"
    local reports_dir="$CLAUDE_SYSTEM_ROOT/reports"
    
    # 最新のログファイルを表示
    echo -e "${WHITE}=== 最新のレポート ===${NC}"
    if [ -d "$reports_dir" ]; then
        ls -la "$reports_dir" | head -10
        echo ""
        
        # 最新の進捗レポート
        local latest_progress=$(ls -t "$reports_dir"/team_progress_*.md 2>/dev/null | head -1)
        if [ -n "$latest_progress" ]; then
            echo -e "${GREEN}📊 最新進捗レポート: $(basename "$latest_progress")${NC}"
            echo -e "${BLUE}内容プレビュー:${NC}"
            head -20 "$latest_progress"
            echo ""
        fi
    else
        echo -e "${YELLOW}⚠️  レポートディレクトリが存在しません${NC}"
    fi
    
    # tmuxセッションのログ
    echo -e "${WHITE}=== tmuxセッション情報 ===${NC}"
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux list-windows -t "$SESSION_NAME"
        tmux list-panes -t "$SESSION_NAME" -a
    else
        echo -e "${YELLOW}⚠️  tmuxセッションが実行されていません${NC}"
    fi
}

# 環境クリーンアップ
cleanup_environment() {
    echo -e "${YELLOW}🧹 環境クリーンアップ中...${NC}"
    
    # tmuxセッション終了確認
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${YELLOW}❓ tmuxセッション '$SESSION_NAME' を終了しますか？ (y/N)${NC}"
        read -r response
        
        if [[ "$response" =~ ^[Yy]$ ]]; then
            tmux kill-session -t "$SESSION_NAME"
            echo -e "${GREEN}✅ tmuxセッション終了${NC}"
        fi
    fi
    
    # Worktreeクリーンアップ
    echo -e "${BLUE}🌳 Worktreeクリーンアップ...${NC}"
    "$SCRIPT_DIR/worktree-manager.sh" cleanup
    
    echo -e "${GREEN}✅ クリーンアップ完了${NC}"
}

# メイン処理
main() {
    case "${1:-}" in
        "init")
            init_parallel_dev
            ;;
        "setup")
            setup_environment
            ;;
        "start")
            start_agents
            ;;
        "assign")
            if [ -z "${2:-}" ]; then
                "$SCRIPT_DIR/team-composer.sh" assign
            else
                "$SCRIPT_DIR/team-composer.sh" assign "$2"
            fi
            ;;
        "status")
            show_overall_status
            ;;
        "sync")
            sync_all_workers
            ;;
        "collect")
            collect_all_progress
            ;;
        "merge")
            merge_worker_results
            ;;
        "compare")
            compare_all_approaches
            ;;
        "connect")
            connect_session
            ;;
        "logs")
            show_logs
            ;;
        "cleanup")
            cleanup_environment
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            show_logo
            echo -e "${RED}❌ 不正なコマンド: ${1:-}${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@" 