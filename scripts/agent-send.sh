#!/bin/bash
# ==============================================================================
# Agent Message Sender - エージェント間メッセージ送信システム
# ==============================================================================
# Description: President/Boss/Worker 3層構造対応のメッセージ送信ツール
# Usage: agent-send.sh <target> [message]
# Dependencies: tmux, Claude CLI
# ==============================================================================

set -e

SESSION_NAME="multiagent"

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 使用方法の表示
show_usage() {
    echo -e "${CYAN}🎯 Agent Message Sender${NC}"
    echo ""
    echo -e "${WHITE}President/Boss/Worker 3層構造対応版${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 <送信先> <メッセージ>"
    echo "  $0 <送信先> -           # 標準入力からメッセージ読み込み"
    echo ""
    echo -e "${GREEN}送信先:${NC}"
    echo "  president  : 👑 PRESIDENT（統括責任者）"
    echo "  boss       : 🎯 BOSS（チームリーダー）"
    echo "  worker1    : 🎨 WORKER1（UI/UXデザイン担当）"
    echo "  worker2    : ⚙️  WORKER2（バックエンド・データ処理担当）"
    echo "  worker3    : 🧪 WORKER3（テスト・品質保証担当）"
    echo "  team       : 🏢 全チーム（BOSS + WORKER1-3）"
    echo "  all        : 🌐 全員（PRESIDENT + BOSS + WORKER1-3）"
    echo ""
    echo -e "${GREEN}BOSS権限:${NC}"
    echo "  --from-boss            # BOSS権限でメッセージ送信"
    echo "  --priority <level>     # 優先度設定 (high/medium/low)"
    echo "  --template <type>      # テンプレート使用 (instruction/review/meeting)"
    echo ""
    echo "例:"
    echo "  $0 president 'TODOアプリを作成してください'"
    echo "  $0 worker1 'ログイン画面のUIを作成してください' --from-boss"
    echo "  $0 team '進捗を報告してください' --priority high"
    echo "  echo 'メッセージ' | $0 worker1 -"
    echo ""
}

# 引数解析
TARGET=""
MESSAGE=""
FROM_BOSS=false
PRIORITY="medium"
TEMPLATE=""

# 引数を解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --from-boss)
            FROM_BOSS=true
            shift
            ;;
        --priority)
            PRIORITY="$2"
            shift 2
            ;;
        --template)
            TEMPLATE="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            if [ -z "$TARGET" ]; then
                TARGET="$1"
            elif [ -z "$MESSAGE" ]; then
                MESSAGE="$1"
            else
                # 残りの引数をオプションとして処理
                case $1 in
                    --from-boss)
                        FROM_BOSS=true
                        ;;
                    --priority)
                        PRIORITY="$2"
                        shift
                        ;;
                    --template)
                        TEMPLATE="$2"
                        shift
                        ;;
                    -*)
                        echo -e "${RED}❌ 不明なオプション: $1${NC}"
                        show_usage
                        exit 1
                        ;;
                    *)
                        echo -e "${RED}❌ 余分な引数: $1${NC}"
                        show_usage
                        exit 1
                        ;;
                esac
            fi
            shift
            ;;
    esac
done

# 標準入力からメッセージを読み込み
if [ "$MESSAGE" = "-" ]; then
    MESSAGE=$(cat)
fi

# 引数チェック
if [ -z "$TARGET" ] || [ -z "$MESSAGE" ]; then
    echo -e "${RED}❌ 送信先とメッセージを指定してください${NC}"
    show_usage
    exit 1
fi

# セッション存在確認
if ! tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo -e "${RED}❌ セッション '$SESSION_NAME' が見つかりません${NC}"
    echo -e "${YELLOW}💡 先に ./setup-multiagent.sh を実行してください${NC}"
    exit 1
fi

# 優先度アイコン取得
get_priority_icon() {
    case "$1" in
        "high") echo "🔥" ;;
        "medium") echo "📋" ;;
        "low") echo "💬" ;;
        *) echo "📋" ;;
    esac
}

# メッセージフォーマット
format_message() {
    local msg="$1"
    local priority_icon=$(get_priority_icon "$PRIORITY")
    local timestamp=$(date '+%Y-%m-%d %H:%M')
    
    if [ "$FROM_BOSS" = true ]; then
        echo "🎯【BOSS指示】$priority_icon [$timestamp]"
        echo ""
        echo "$msg"
        echo ""
        echo "---"
        echo "From: BOSS (Team Leader)"
        echo "Priority: $PRIORITY"
    else
        echo "$priority_icon [$timestamp] $msg"
    fi
}

# テンプレート適用
apply_template() {
    local msg="$1"
    local template="$2"
    
    case "$template" in
        "instruction")
            echo "🎯【指示】"
            echo ""
            echo "$msg"
            echo ""
            echo "📋 対応方法："
            echo "1. 内容を確認"
            echo "2. 不明点があれば質問"
            echo "3. 実装・対応"
            echo "4. 完了報告"
            ;;
        "review")
            echo "📝【レビュー】"
            echo ""
            echo "$msg"
            echo ""
            echo "🎯 改善点があれば対応をお願いします"
            ;;
        "meeting")
            echo "📅【ミーティング】"
            echo ""
            echo "$msg"
            echo ""
            echo "⏰ 準備をお願いします"
            ;;
        *)
            echo "$msg"
            ;;
    esac
}

# メッセージ送信関数
send_message() {
    local pane=$1
    local role=$2
    local msg=$3
    
    echo -e "${BLUE}📤 $role にメッセージを送信中...${NC}"
    
    # テンプレート適用
    if [ -n "$TEMPLATE" ]; then
        msg=$(apply_template "$msg" "$TEMPLATE")
    fi
    
    # メッセージフォーマット
    local formatted_msg=$(format_message "$msg")
    
    # メッセージを送信（複数行対応）
    echo "$formatted_msg" | while IFS= read -r line; do
        tmux send-keys -t $SESSION_NAME:$pane "echo '$line'" C-m
    done
    
    echo -e "${GREEN}✅ 送信完了: $role${NC}"
}

# 送信先に応じてメッセージを送信
case $TARGET in
    "president")
        send_message "0" "👑 PRESIDENT" "$MESSAGE"
        ;;
    "boss")
        send_message "1.0" "🎯 BOSS" "$MESSAGE"
        ;;
    "worker1")
        send_message "1.1" "🎨 WORKER1" "$MESSAGE"
        ;;
    "worker2")
        send_message "1.2" "⚙️  WORKER2" "$MESSAGE"
        ;;
    "worker3")
        send_message "1.3" "🧪 WORKER3" "$MESSAGE"
        ;;
    "team")
        echo -e "${CYAN}🏢 チーム全体にメッセージを送信中...${NC}"
        send_message "1.0" "🎯 BOSS" "$MESSAGE"
        send_message "1.1" "🎨 WORKER1" "$MESSAGE"
        send_message "1.2" "⚙️  WORKER2" "$MESSAGE"
        send_message "1.3" "🧪 WORKER3" "$MESSAGE"
        echo -e "${GREEN}✅ チーム全体への送信完了${NC}"
        ;;
    "all")
        echo -e "${CYAN}🌐 全員にメッセージを送信中...${NC}"
        send_message "0" "👑 PRESIDENT" "$MESSAGE"
        send_message "1.0" "🎯 BOSS" "$MESSAGE"
        send_message "1.1" "🎨 WORKER1" "$MESSAGE"
        send_message "1.2" "⚙️  WORKER2" "$MESSAGE"
        send_message "1.3" "🧪 WORKER3" "$MESSAGE"
        echo -e "${GREEN}✅ 全員への送信完了${NC}"
        ;;
    *)
        echo -e "${RED}❌ 不正な送信先: $TARGET${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

echo ""
echo -e "${WHITE}📋 送信内容: $MESSAGE${NC}"
echo -e "${WHITE}📅 送信時刻: $(date)${NC}"
if [ "$FROM_BOSS" = true ]; then
    echo -e "${YELLOW}🎯 BOSS権限: 有効${NC}"
fi
if [ -n "$TEMPLATE" ]; then
    echo -e "${BLUE}📝 テンプレート: $TEMPLATE${NC}"
fi
echo -e "${WHITE}⚡ 優先度: $PRIORITY${NC}"
echo ""
echo -e "${CYAN}💡 確認方法:${NC}"
echo "   tmux attach-session -t $SESSION_NAME" 