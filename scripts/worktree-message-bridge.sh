#!/bin/bash

# Worktree Message Bridge - worktree環境とtmux環境の橋渡し
# BOSSからWorkerへの指示を適切に配信し、進捗を収集するシステム

set -e

# 設定
PROJECT_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WORKTREE_BASE="$PROJECT_ROOT/worktrees"
CLAUDE_SYSTEM_ROOT="$(dirname "$0")/.."
MESSAGE_DIR="$CLAUDE_SYSTEM_ROOT/messages"
SESSION_NAME="multiagent"

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# メッセージディレクトリ初期化
init_message_system() {
    echo -e "${CYAN}📬 メッセージングシステム初期化中...${NC}"
    
    mkdir -p "$MESSAGE_DIR"/{inbox,outbox,archive}
    
    # 各Workerのメッセージボックス作成
    for worker in worker1 worker2 worker3; do
        mkdir -p "$MESSAGE_DIR/inbox/$worker"
        mkdir -p "$MESSAGE_DIR/outbox/$worker"
    done
    
    echo -e "${GREEN}✅ メッセージングシステム初期化完了${NC}"
}

# BOSSからWorkerへのメッセージ送信
send_boss_message() {
    local target_worker=$1
    local message_type=$2
    local message_content="$3"
    local priority=${4:-medium}
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local message_id="boss_${timestamp}_${RANDOM}"
    local message_file="$MESSAGE_DIR/inbox/$target_worker/${message_id}.msg"
    
    echo -e "${BLUE}📤 BOSSメッセージ送信: $target_worker${NC}"
    
    cat > "$message_file" << EOF
# BOSS指示メッセージ

**メッセージID**: $message_id
**送信者**: BOSS
**受信者**: $target_worker
**種別**: $message_type
**優先度**: $priority
**送信日時**: $(date)

---

## 指示内容

$message_content

---

## 対応要求

1. このメッセージを確認したら、PROGRESS.mdに確認済みと記録してください
2. 不明点がある場合は、outboxにレスポンスファイルを作成してください
3. 作業完了時は、成果物と共に報告してください

**確認期限**: $(date -d '+1 hour' '+%Y-%m-%d %H:%M')
EOF

    # worktree環境にも配信
    local worktree_path="$WORKTREE_BASE/$target_worker"
    if [ -d "$worktree_path" ]; then
        cp "$message_file" "$worktree_path/LATEST_MESSAGE.md"
        echo -e "${GREEN}📋 Worktree環境にも配信完了${NC}"
    fi
    
    echo -e "${GREEN}✅ メッセージ送信完了: $message_id${NC}"
}

# Workerからの返信収集
collect_worker_responses() {
    echo -e "${CYAN}📥 Worker返信収集中...${NC}"
    
    for worker in worker1 worker2 worker3; do
        local outbox_dir="$MESSAGE_DIR/outbox/$worker"
        local worktree_path="$WORKTREE_BASE/$worker"
        
        echo -e "${WHITE}=== $worker 返信確認 ===${NC}"
        
        # worktree環境からメッセージを収集
        if [ -d "$worktree_path" ]; then
            # PROGRESS.mdの更新確認
            if [ -f "$worktree_path/PROGRESS.md" ]; then
                local last_update=$(stat -f "%m" "$worktree_path/PROGRESS.md" 2>/dev/null || stat -c "%Y" "$worktree_path/PROGRESS.md" 2>/dev/null)
                local current_time=$(date +%s)
                local time_diff=$((current_time - last_update))
                
                if [ $time_diff -lt 3600 ]; then  # 1時間以内の更新
                    echo -e "${GREEN}📝 最新進捗あり (${time_diff}秒前)${NC}"
                else
                    echo -e "${YELLOW}📝 進捗更新が古い (${time_diff}秒前)${NC}"
                fi
            fi
            
            # 返信ファイルの確認
            if [ -f "$worktree_path/RESPONSE.md" ]; then
                echo -e "${BLUE}💬 返信あり${NC}"
                
                # 返信をoutboxに移動
                local timestamp=$(date '+%Y%m%d_%H%M%S')
                mv "$worktree_path/RESPONSE.md" "$outbox_dir/response_${timestamp}.md"
                echo -e "${GREEN}📤 返信をoutboxに移動${NC}"
            fi
        fi
        
        # outboxの内容確認
        local response_count=$(find "$outbox_dir" -name "*.md" 2>/dev/null | wc -l)
        if [ $response_count -gt 0 ]; then
            echo -e "${BLUE}📬 未読返信: ${response_count}件${NC}"
        else
            echo -e "${YELLOW}📬 返信なし${NC}"
        fi
        
        echo ""
    done
}

# メッセージ状況のダッシュボード表示
show_message_dashboard() {
    echo -e "${CYAN}📊 メッセージングダッシュボード${NC}"
    echo ""
    
    echo -e "${WHITE}=== 送信状況 ===${NC}"
    for worker in worker1 worker2 worker3; do
        local inbox_count=$(find "$MESSAGE_DIR/inbox/$worker" -name "*.msg" 2>/dev/null | wc -l)
        local outbox_count=$(find "$MESSAGE_DIR/outbox/$worker" -name "*.md" 2>/dev/null | wc -l)
        
        echo -e "${GREEN}$worker${NC}"
        echo -e "   📥 受信待ち: $inbox_count"
        echo -e "   📤 返信待ち: $outbox_count"
    done
    
    echo ""
    echo -e "${WHITE}=== Worktree同期状況 ===${NC}"
    for worker in worker1 worker2 worker3; do
        local worktree_path="$WORKTREE_BASE/$worker"
        if [ -d "$worktree_path" ]; then
            if [ -f "$worktree_path/LATEST_MESSAGE.md" ]; then
                local msg_time=$(stat -f "%m" "$worktree_path/LATEST_MESSAGE.md" 2>/dev/null || stat -c "%Y" "$worktree_path/LATEST_MESSAGE.md" 2>/dev/null)
                local current_time=$(date +%s)
                local time_diff=$((current_time - msg_time))
                
                echo -e "${GREEN}$worker${NC}: 最新メッセージ (${time_diff}秒前)"
            else
                echo -e "${YELLOW}$worker${NC}: メッセージなし"
            fi
        else
            echo -e "${RED}$worker${NC}: Worktreeなし"
        fi
    done
}

# tmux環境での作業ディレクトリ設定
setup_tmux_worktree_integration() {
    echo -e "${CYAN}🖥️  tmux-worktree統合設定中...${NC}"
    
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}❌ tmuxセッション '$SESSION_NAME' が存在しません${NC}"
        return 1
    fi
    
    # 各Workerペインで適切なworktreeディレクトリに移動
    for i in 1 2 3; do
        local worker="worker$i"
        local worktree_path="$WORKTREE_BASE/$worker"
        
        if [ -d "$worktree_path" ]; then
            echo -e "${BLUE}🔄 Worker$i ペインを $worktree_path に設定${NC}"
            
            # tmuxペインでディレクトリ変更とプロンプト設定
            tmux send-keys -t "$SESSION_NAME:1.$i" "cd $worktree_path" Enter
            tmux send-keys -t "$SESSION_NAME:1.$i" "export PS1='[$worker:\w]$ '" Enter
            tmux send-keys -t "$SESSION_NAME:1.$i" "echo '🎯 $worker ワークスペース準備完了'" Enter
            tmux send-keys -t "$SESSION_NAME:1.$i" "echo '📁 作業ディレクトリ: \$(pwd)'" Enter
            tmux send-keys -t "$SESSION_NAME:1.$i" "echo '🌿 ブランチ: \$(git branch --show-current)'" Enter
        fi
    done
    
    echo -e "${GREEN}✅ tmux-worktree統合完了${NC}"
}

# 自動同期デーモン（バックグラウンド実行用）
start_sync_daemon() {
    local pid_file="$MESSAGE_DIR/sync_daemon.pid"
    
    if [ -f "$pid_file" ] && kill -0 "$(cat "$pid_file")" 2>/dev/null; then
        echo -e "${YELLOW}⚠️  同期デーモンは既に実行中です${NC}"
        return
    fi
    
    echo -e "${CYAN}🔄 自動同期デーモン開始...${NC}"
    
    (
        while true; do
            sleep 30  # 30秒間隔
            
            # 静かに返信収集
            collect_worker_responses > /dev/null 2>&1
            
            # アーカイブ処理（1時間以上古いメッセージ）
            find "$MESSAGE_DIR/inbox" -name "*.msg" -mtime +1h -exec mv {} "$MESSAGE_DIR/archive/" \; 2>/dev/null || true
            find "$MESSAGE_DIR/outbox" -name "*.md" -mtime +1h -exec mv {} "$MESSAGE_DIR/archive/" \; 2>/dev/null || true
        done
    ) &
    
    echo $! > "$pid_file"
    echo -e "${GREEN}✅ 同期デーモン開始 (PID: $(cat "$pid_file"))${NC}"
}

# 同期デーモン停止
stop_sync_daemon() {
    local pid_file="$MESSAGE_DIR/sync_daemon.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid"
            rm "$pid_file"
            echo -e "${GREEN}✅ 同期デーモン停止${NC}"
        else
            echo -e "${YELLOW}⚠️  デーモンは既に停止しています${NC}"
            rm "$pid_file"
        fi
    else
        echo -e "${YELLOW}⚠️  デーモンは実行されていません${NC}"
    fi
}

# メイン処理
main() {
    case "${1:-}" in
        "init")
            init_message_system
            ;;
        "send")
            if [ $# -lt 4 ]; then
                echo -e "${RED}❌ 使用方法: $0 send <worker> <type> <message> [priority]${NC}"
                exit 1
            fi
            send_boss_message "$2" "$3" "$4" "${5:-medium}"
            ;;
        "collect")
            collect_worker_responses
            ;;
        "dashboard")
            show_message_dashboard
            ;;
        "setup-tmux")
            setup_tmux_worktree_integration
            ;;
        "start-daemon")
            start_sync_daemon
            ;;
        "stop-daemon")
            stop_sync_daemon
            ;;
        *)
            echo -e "${CYAN}🔗 Worktree Message Bridge${NC}"
            echo ""
            echo "使用方法:"
            echo "  $0 init                              # メッセージングシステム初期化"
            echo "  $0 send <worker> <type> <message>    # BOSSメッセージ送信"
            echo "  $0 collect                           # Worker返信収集"
            echo "  $0 dashboard                         # 状況確認"
            echo "  $0 setup-tmux                        # tmux統合設定"
            echo "  $0 start-daemon                      # 自動同期開始"
            echo "  $0 stop-daemon                       # 自動同期停止"
            ;;
    esac
}

main "$@" 