#!/bin/bash

# Boss Commander - BOSSからWorkerへの指示・分配システム
# planlist.mdベースでBOSSが各Workerに方式案を指示・分配

set -e

# 設定
PROJECT_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
CLAUDE_SYSTEM_ROOT="$(dirname "$0")/.."
SCRIPT_DIR="$(dirname "$0")"
PLANLIST_FILE="$CLAUDE_SYSTEM_ROOT/planlist.md"
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

# BOSSロゴ表示
show_boss_logo() {
    echo -e "${PURPLE}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   🎯 BOSS COMMANDER                                          ║
║                                                               ║
║   チームリーダーとしてWorkerに指示・分配を行います             ║
║                                                               ║
║   ┌─────────────────────────────────────────────────────────┐ ║
║   │  🎯 BOSS (あなた)                                       │ ║
║   └─────────────────────────────────────────────────────────┘ ║
║                              │                               ║
║              ┌───────────────┼───────────────┐               ║
║              ▼               ▼               ▼               ║
║   ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         ║
║   │🎨 WORKER1   │  │⚙️ WORKER2   │  │🧪 WORKER3   │         ║
║   │UI/UX        │  │Backend      │  │Test         │         ║
║   └─────────────┘  └─────────────┘  └─────────────┘         ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 使用方法表示
show_usage() {
    echo -e "${CYAN}🎯 Boss Commander${NC}"
    echo ""
    echo -e "${WHITE}BOSSからWorkerへの指示・分配システム${NC}"
    echo ""
    echo "使用方法:"
    echo "  $0 <コマンド> [オプション]"
    echo ""
    echo -e "${GREEN}■ 方式案管理${NC}"
    echo -e "  ${GREEN}analyze${NC}          - planlist.mdを分析"
    echo -e "  ${GREEN}assign${NC}           - 方式案を自動分配"
    echo -e "  ${GREEN}assign${NC} <Worker> <方式案> - 特定分配"
    echo -e "  ${GREEN}reassign${NC}         - 分配の再調整"
    echo ""
    echo -e "${GREEN}■ チーム指示${NC}"
    echo -e "  ${GREEN}instruct${NC} <Worker> - 個別指示"
    echo -e "  ${GREEN}broadcast${NC}        - 全体指示"
    echo -e "  ${GREEN}meeting${NC}          - チームミーティング開催"
    echo ""
    echo -e "${GREEN}■ 進捗管理${NC}"
    echo -e "  ${GREEN}check${NC}            - 全Worker進捗確認"
    echo -e "  ${GREEN}review${NC} <Worker>  - 個別レビュー"
    echo -e "  ${GREEN}feedback${NC}         - フィードバック送信"
    echo ""
    echo -e "${GREEN}■ 調整・支援${NC}"
    echo -e "  ${GREEN}coordinate${NC}       - Worker間調整"
    echo -e "  ${GREEN}support${NC} <Worker> - 個別支援"
    echo -e "  ${GREEN}escalate${NC}         - PRESIDENT報告"
    echo ""
    echo "例:"
    echo -e "  ${YELLOW}$0 analyze${NC}                 # planlist.md分析"
    echo -e "  ${YELLOW}$0 assign${NC}                  # 自動分配"
    echo -e "  ${YELLOW}$0 instruct worker1${NC}        # Worker1に指示"
    echo -e "  ${YELLOW}$0 check${NC}                   # 進捗確認"
    echo ""
}

# planlist.md分析（BOSS視点）
analyze_planlist_as_boss() {
    show_boss_logo
    echo -e "${CYAN}🎯 BOSS視点でのplanlist.md分析${NC}"
    echo ""
    
    if [ ! -f "$PLANLIST_FILE" ]; then
        echo -e "${RED}❌ planlist.mdが見つかりません: $PLANLIST_FILE${NC}"
        echo -e "${YELLOW}💡 PRESIDENTに planlist.md の作成を依頼してください${NC}"
        exit 1
    fi
    
    # 方式案の抽出と分析
    local approach_count=$(grep -c "^## 方式案[0-9]*:" "$PLANLIST_FILE")
    
    echo -e "${WHITE}📋 分析結果${NC}"
    echo -e "   総方式案数: ${GREEN}$approach_count${NC}"
    echo -e "   利用可能Worker: ${GREEN}3名${NC}"
    echo ""
    
    # 各方式案の詳細分析
    local i=1
    while [ $i -le $approach_count ]; do
        echo -e "${WHITE}方式案$i:${NC}"
        
        # タイトル抽出
        local title=$(grep "^## 方式案$i:" "$PLANLIST_FILE" | sed 's/^## 方式案[0-9]*:[[:space:]]*//')
        echo -e "   📌 ${GREEN}$title${NC}"
        
        # 技術スタック抽出
        local tech_stack=$(awk '/^## 方式案'$i':/{flag=1} /^## 方式案[0-9]+:/ && !/^## 方式案'$i':/{flag=0} flag && /\*\*技術スタック\*\*:/{print; getline; print}' "$PLANLIST_FILE" | grep -v "技術スタック" | head -1)
        if [ -n "$tech_stack" ]; then
            echo -e "   🛠️  技術: $tech_stack"
        fi
        
        # 実装要件の概算
        local requirements=$(awk '/^## 方式案'$i':/{flag=1} /^## 方式案[0-9]+:/ && !/^## 方式案'$i':/{flag=0} flag && /\*\*実装要件\*\*:/{flag2=1; next} flag2 && /^[0-9]+\./{count++} flag2 && /^\*\*/{flag2=0} END{print count+0}' "$PLANLIST_FILE")
        echo -e "   📋 実装要件: ${BLUE}${requirements}項目${NC}"
        
        # 指定Worker抽出（planlist.mdから）
        local assigned_worker=$(awk '/^### 方式案'$i':/{flag=1} /^### 方式案[0-9]+:/ && !/^### 方式案'$i':/{flag=0} flag && /\*\*担当Worker\*\*:/{print; exit}' "$PLANLIST_FILE" | sed 's/.*: *\([^ ]*\).*/\1/')
        
        # 推奨Worker判定（従来のロジック）
        local recommended_worker=""
        if echo "$title $tech_stack" | grep -qi -E "(ui|ux|react|frontend|design)"; then
            recommended_worker="🎨 Worker1 (UI/UX)"
        elif echo "$title $tech_stack" | grep -qi -E "(api|backend|database|server|node)"; then
            recommended_worker="⚙️ Worker2 (Backend)"
        elif echo "$title $tech_stack" | grep -qi -E "(test|quality|docker|kubernetes)"; then
            recommended_worker="🧪 Worker3 (Test)"
        else
            recommended_worker="🤔 要検討"
        fi
        
        # 指定Workerと推奨Workerの表示
        if [ -n "$assigned_worker" ]; then
            echo -e "   👤 指定担当: ${GREEN}$assigned_worker${NC}"
            echo -e "   🎯 推奨担当: $recommended_worker"
            
            # 一致確認
            if echo "$assigned_worker" | grep -q "worker1" && echo "$recommended_worker" | grep -q "Worker1"; then
                echo -e "   ✅ ${GREEN}最適マッチ${NC}"
            elif echo "$assigned_worker" | grep -q "worker2" && echo "$recommended_worker" | grep -q "Worker2"; then
                echo -e "   ✅ ${GREEN}最適マッチ${NC}"
            elif echo "$assigned_worker" | grep -q "worker3" && echo "$recommended_worker" | grep -q "Worker3"; then
                echo -e "   ✅ ${GREEN}最適マッチ${NC}"
            else
                echo -e "   ⚠️  ${YELLOW}要検討${NC}"
            fi
        else
            echo -e "   👤 推奨担当: $recommended_worker"
            echo -e "   📝 ${YELLOW}planlist.mdで担当Worker未指定${NC}"
        fi
        
        echo ""
        i=$((i + 1))
    done
    
    # BOSSとしての分配戦略提案
    echo -e "${BLUE}🎯 BOSS推奨分配戦略${NC}"
    if [ $approach_count -eq 3 ]; then
        echo -e "   ✅ ${GREEN}最適配置${NC}: 各Workerが1つの方式案を担当"
        echo -e "   📈 期待効率: 100% (専門性最大活用)"
    elif [ $approach_count -gt 3 ]; then
        echo -e "   ⚡ ${YELLOW}高負荷配置${NC}: 一部Workerが複数担当"
        echo -e "   📈 期待効率: 80% (負荷分散要)"
    else
        echo -e "   🎯 ${CYAN}集中配置${NC}: 複数Workerで1つの方式案"
        echo -e "   📈 期待効率: 120% (協力効果)"
    fi
    
    echo ""
    echo -e "${YELLOW}💡 次のアクション:${NC}"
    echo -e "   1. ${CYAN}$0 assign${NC} で自動分配"
    echo -e "   2. ${CYAN}$0 instruct <worker>${NC} で個別指示"
    echo -e "   3. ${CYAN}$0 meeting${NC} でキックオフミーティング"
}

# 方式案の自動分配
auto_assign_as_boss() {
    echo -e "${CYAN}🎯 BOSSによる方式案自動分配${NC}"
    echo ""
    
    # planlist.mdから指定Workerを読み取って分配
    assign_from_planlist
    
    echo ""
    echo -e "${GREEN}📋 分配完了後のBOSS指示を送信中...${NC}"
    
    # メッセージングシステム経由で分配完了を通知
    echo -e "${BLUE}📬 メッセージングシステム経由で通知送信...${NC}"
    
    # 各Workerに分配完了の指示を送信
    for worker in worker1 worker2 worker3; do
        local role=""
        case "$worker" in
            "worker1") role="開発者" ;;
            "worker2") role="開発者" ;;
            "worker3") role="開発者" ;;
        esac
        
        local instruction="
🎯 【BOSS指示】方式案分配完了

$role として、配布された方式案の検討を開始してください。

📋 確認事項：
1. ASSIGNMENT.md の内容確認
2. 技術スタックの理解
3. 実装要件の把握
4. リスク・課題の洗い出し

⏰ 期限：
- 初期分析: 24時間以内
- 詳細検討: 72時間以内
- 実装開始: 1週間以内

📊 報告方法：
- PROGRESS.md に進捗を記録
- 課題があれば即座にBOSSに報告
- 他Workerとの連携が必要な場合は調整依頼

🚀 専門性を活かして、革新的なソリューションを期待しています！

質問・相談があればいつでもBOSSまで。
        "
        
        send_instruction_to_worker "$worker" "$instruction"
    done
}

# planlist.mdから指定Workerを読み取って分配
assign_from_planlist() {
    echo -e "${BLUE}📋 planlist.mdの分配戦略に基づく自動分配${NC}"
    echo ""
    
    local approach_count=$(grep -c "^## 方式案[0-9]*:" "$PLANLIST_FILE")
    
    # 各方式案の担当Worker抽出と分配
    local i=1
    while [ $i -le $approach_count ]; do
        # 方式案タイトル
        local title=$(grep "^## 方式案$i:" "$PLANLIST_FILE" | sed 's/^## 方式案[0-9]*:[[:space:]]*//')
        
        # 指定Worker抽出
        local assigned_worker=$(awk '/^### 方式案'$i':/{flag=1} /^### 方式案[0-9]+:/ && !/^### 方式案'$i':/{flag=0} flag && /\*\*担当Worker\*\*:/{print; exit}' "$PLANLIST_FILE" | sed 's/.*: *\([^ ]*\).*/\1/')
        
        if [ -n "$assigned_worker" ]; then
            echo -e "${WHITE}方式案$i: $title${NC}"
            echo -e "   👤 担当: ${GREEN}$assigned_worker${NC}"
            
            # 該当Workerに個別分配指示
            assign_specific_approach_to_worker "$assigned_worker" "$i" "$title"
            echo ""
        else
            echo -e "${WHITE}方式案$i: $title${NC}"
            echo -e "   ⚠️  ${YELLOW}担当Worker未指定 - 自動推奨に基づく分配${NC}"
            
            # 従来の推奨ロジックで分配
            local tech_stack=$(awk '/^## 方式案'$i':/{flag=1} /^## 方式案[0-9]+:/ && !/^## 方式案'$i':/{flag=0} flag && /\*\*技術スタック\*\*:/{print; getline; print}' "$PLANLIST_FILE" | grep -v "技術スタック" | head -1)
            
            if echo "$title $tech_stack" | grep -qi -E "(ui|ux|react|frontend|design)"; then
                assign_specific_approach_to_worker "worker1" "$i" "$title"
            elif echo "$title $tech_stack" | grep -qi -E "(api|backend|database|server|node)"; then
                assign_specific_approach_to_worker "worker2" "$i" "$title"
            elif echo "$title $tech_stack" | grep -qi -E "(test|quality|docker|kubernetes)"; then
                assign_specific_approach_to_worker "worker3" "$i" "$title"
            else
                echo -e "   ${RED}❌ 適切なWorkerを特定できませんでした${NC}"
            fi
            echo ""
        fi
        
        i=$((i + 1))
    done
}

# 特定の方式案を特定のWorkerに分配（内部関数）
assign_specific_approach_to_worker() {
    local worker=$1
    local approach_num=$2
    local approach_title=$3
    
    local role=""
    case "$worker" in
        "worker1") role="開発者" ;;
        "worker2") role="開発者" ;;
        "worker3") role="開発者" ;;
    esac
    
    echo -e "   🎯 ${GREEN}$worker ($role) に方式案$approach_num を分配${NC}"
    
    # 個別分配ファイル作成
    local assignment_file="$CLAUDE_SYSTEM_ROOT/assignments/${worker}_approach_${approach_num}.md"
    mkdir -p "$(dirname "$assignment_file")"
    
    # 方式案の詳細を抽出
    local approach_details=$(awk '/^## 方式案'$approach_num':/{flag=1} /^## 方式案[0-9]+:/ && !/^## 方式案'$approach_num':/{flag=0} flag' "$PLANLIST_FILE")
    
    cat > "$assignment_file" << EOF
# 🎯 方式案${approach_num}分配書

**担当Worker**: $worker ($role)  
**分配日時**: $(date '+%Y-%m-%d %H:%M:%S')  
**分配者**: BOSS

---

## 📋 方式案詳細

$approach_details

---

## 🎯 BOSSからの指示

$role として、上記方式案の責任者に任命します。

### 📋 実行項目
1. 技術スタックの詳細調査
2. 実装要件の分析・詳細化
3. リスク評価と対策案の策定
4. 実装計画の作成
5. プロトタイプの実装

### ⏰ スケジュール
- 初期分析: 24時間以内
- 詳細設計: 72時間以内
- プロトタイプ: 1週間以内

### 📊 報告方法
- 進捗は PROGRESS.md に記録
- 課題・質問は即座にBOSSに報告
- 他Workerとの連携が必要な場合は調整依頼

### 🎖️ 期待成果
あなたの専門性を最大限活かし、革新的で実用的なソリューションを期待しています。

---
**BOSS**
EOF
    
    echo -e "   📝 分配書作成: $assignment_file"
}

# 特定の方式案を特定のWorkerに分配
assign_specific() {
    local worker=$1
    local approach_num=$2
    
    if [ -z "$worker" ] || [ -z "$approach_num" ]; then
        echo -e "${RED}❌ 使用方法: $0 assign <Worker> <方式案番号>${NC}"
        echo -e "${YELLOW}例: $0 assign worker1 2${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}🎯 特定分配: $worker に方式案$approach_num${NC}"
    
    # team-composer.shを使用して特定分配
    "$SCRIPT_DIR/team-composer.sh" assign "$approach_num"
    
    # BOSSからの個別指示
    local role=""
    case "$worker" in
        "worker1") role="開発者" ;;
        "worker2") role="開発者" ;;
        "worker3") role="開発者" ;;
    esac
    
    local instruction="
🎯 【BOSS特別指示】方式案${approach_num}の担当任命

$role として、方式案${approach_num}の責任者に任命します。

🎖️ 任命理由：
- あなたの専門性が最も活かせる方式案
- チーム全体の成功の鍵となる重要な役割

📋 期待する成果：
1. 技術的実現可能性の詳細分析
2. 実装計画の策定
3. リスク評価と対策案
4. プロトタイプの実装

⚡ 優先度：HIGH
🤝 サポート：必要な支援は遠慮なく要請してください

この方式案の成功があなたの手にかかっています。
BOSSとして全面的にサポートします！
    "
    
    send_instruction_to_worker "$worker" "$instruction"
}

# Workerに指示を送信
send_instruction_to_worker() {
    local worker=$1
    local instruction=$2
    
    # agent-send.shを使用して指示送信
    if [ -f "$SCRIPT_DIR/agent-send.sh" ]; then
        echo "$instruction" | "$SCRIPT_DIR/agent-send.sh" "$worker" - --from-boss
        echo -e "${GREEN}✅ ${worker}に指示送信完了${NC}"
    else
        # tmux経由で直接送信
        if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            local pane_map=""
            case "$worker" in
                "worker1") pane_map="1.1" ;;
                "worker2") pane_map="1.2" ;;
                "worker3") pane_map="1.3" ;;
            esac
            
            if [ -n "$pane_map" ]; then
                tmux send-keys -t "$SESSION_NAME:$pane_map" "echo '🎯 BOSSからの指示:'" C-m
                echo "$instruction" | while IFS= read -r line; do
                    tmux send-keys -t "$SESSION_NAME:$pane_map" "echo '$line'" C-m
                done
                echo -e "${GREEN}✅ ${worker}に指示送信完了（tmux経由）${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  tmuxセッションが見つかりません。指示をファイルに保存します${NC}"
            local instruction_file="$CLAUDE_SYSTEM_ROOT/instructions/${worker}_$(date +%Y%m%d_%H%M%S).md"
            mkdir -p "$(dirname "$instruction_file")"
            echo "$instruction" > "$instruction_file"
            echo -e "${GREEN}📝 指示保存: $instruction_file${NC}"
        fi
    fi
}

# 個別Workerに指示
instruct_worker() {
    local worker=$1
    
    if [ -z "$worker" ]; then
        echo -e "${YELLOW}利用可能なWorker: worker1, worker2, worker3${NC}"
        echo -e "${CYAN}どのWorkerに指示しますか？${NC}"
        read -r worker
    fi
    
    case "$worker" in
        "worker1"|"worker2"|"worker3")
            ;;
        *)
            echo -e "${RED}❌ 無効なWorker: $worker${NC}"
            exit 1
            ;;
    esac
    
    local role=""
    case "$worker" in
        "worker1") role="開発者" ;;
        "worker2") role="開発者" ;;
        "worker3") role="開発者" ;;
    esac
    
    echo -e "${CYAN}🎯 ${worker} (${role}) への指示内容を入力してください${NC}"
    echo -e "${YELLOW}（複数行可能。終了するには空行でEnter）${NC}"
    echo ""
    
    local instruction=""
    local line=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            break
        fi
        instruction="${instruction}${line}\n"
    done
    
    if [ -z "$instruction" ]; then
        echo -e "${YELLOW}⚠️  指示が入力されませんでした${NC}"
        exit 1
    fi
    
    # BOSSヘッダーを追加
    local boss_instruction="
🎯 【BOSS指示】$(date '+%Y-%m-%d %H:%M')

${role}へ：

$(echo -e "$instruction")

---
BOSSより
    "
    
    send_instruction_to_worker "$worker" "$boss_instruction"
}

# 全体指示（ブロードキャスト）
broadcast_instruction() {
    echo -e "${CYAN}🎯 全Workerへの指示内容を入力してください${NC}"
    echo -e "${YELLOW}（複数行可能。終了するには空行でEnter）${NC}"
    echo ""
    
    local instruction=""
    local line=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            break
        fi
        instruction="${instruction}${line}\n"
    done
    
    if [ -z "$instruction" ]; then
        echo -e "${YELLOW}⚠️  指示が入力されませんでした${NC}"
        exit 1
    fi
    
    # 全Workerに送信
    for worker in worker1 worker2 worker3; do
        local role=""
        case "$worker" in
            "worker1") role="開発者" ;;
            "worker2") role="開発者" ;;
            "worker3") role="開発者" ;;
        esac
        
        local boss_instruction="
🎯 【BOSS全体指示】$(date '+%Y-%m-%d %H:%M')

全Worker共通指示：

$(echo -e "$instruction")

あなたの役割（${role}）の視点から対応してください。

---
BOSSより
        "
        
        send_instruction_to_worker "$worker" "$boss_instruction"
    done
    
    echo -e "${GREEN}✅ 全Workerに指示送信完了${NC}"
}

# チームミーティング開催
hold_team_meeting() {
    echo -e "${CYAN}🎯 チームミーティング開催${NC}"
    echo ""
    
    local meeting_agenda="
📅 【チームミーティング】$(date '+%Y-%m-%d %H:%M')

🎯 BOSSより全Workerへ：

本日のチームミーティングを開催します。

📋 アジェンダ：
1. 各Workerの進捗報告（5分ずつ）
2. 課題・ブロッカーの共有
3. Worker間の連携事項
4. 今後のスケジュール確認
5. 質疑応答

⏰ 時間：30分程度
🎤 発言順：Worker1 → Worker2 → Worker3

📊 報告内容：
- 現在の進捗状況
- 完了した作業
- 進行中の作業
- 課題・ブロッカー
- 他Workerへの依頼・連携事項
- 今後の予定

🤝 連携を深めて、チーム力を最大化しましょう！

それでは、Worker1から報告をお願いします。

---
BOSS
    "
    
    # 全Workerに送信
    for worker in worker1 worker2 worker3; do
        send_instruction_to_worker "$worker" "$meeting_agenda"
    done
    
    echo -e "${GREEN}✅ チームミーティング開催通知送信完了${NC}"
    echo -e "${YELLOW}💡 tmuxセッションで各Workerの発言を確認してください${NC}"
}

# 進捗確認
check_progress() {
    echo -e "${CYAN}🎯 BOSS進捗確認${NC}"
    echo ""
    
    # team-composer.shの進捗収集機能を使用
    "$SCRIPT_DIR/team-composer.sh" collect
    
    # BOSSとしての追加確認指示
    local progress_request="
📊 【BOSS進捗確認】$(date '+%Y-%m-%d %H:%M')

現在の作業状況を報告してください。

📋 報告項目：
1. 今日完了した作業
2. 現在進行中の作業
3. 明日の予定
4. 課題・ブロッカー
5. 他Workerとの連携状況
6. BOSSへの相談事項

⏰ 報告期限：30分以内
📝 報告方法：PROGRESS.mdの更新

チームの進捗を把握するため、詳細な報告をお願いします。

---
BOSS
    "
    
    for worker in worker1 worker2 worker3; do
        send_instruction_to_worker "$worker" "$progress_request"
    done
    
    echo -e "${GREEN}✅ 進捗確認指示送信完了${NC}"
}

# 個別レビュー
review_worker() {
    local worker=$1
    
    if [ -z "$worker" ]; then
        echo -e "${YELLOW}レビュー対象Worker: worker1, worker2, worker3${NC}"
        echo -e "${CYAN}どのWorkerをレビューしますか？${NC}"
        read -r worker
    fi
    
    case "$worker" in
        "worker1"|"worker2"|"worker3")
            ;;
        *)
            echo -e "${RED}❌ 無効なWorker: $worker${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${CYAN}🎯 ${worker} のレビューコメントを入力してください${NC}"
    echo -e "${YELLOW}（複数行可能。終了するには空行でEnter）${NC}"
    echo ""
    
    local review_comment=""
    local line=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            break
        fi
        review_comment="${review_comment}${line}\n"
    done
    
    if [ -z "$review_comment" ]; then
        echo -e "${YELLOW}⚠️  レビューコメントが入力されませんでした${NC}"
        exit 1
    fi
    
    local role=""
    case "$worker" in
        "worker1") role="開発者" ;;
        "worker2") role="開発者" ;;
        "worker3") role="開発者" ;;
    esac
    
    local boss_review="
📝 【BOSSレビュー】$(date '+%Y-%m-%d %H:%M')

${role} ${worker} へのレビュー：

$(echo -e "$review_comment")

🎯 今後の期待：
専門性を活かして、さらなる品質向上を期待しています。
不明点があれば遠慮なくBOSSまで相談してください。

---
BOSS
    "
    
    send_instruction_to_worker "$worker" "$boss_review"
}

# Worker間調整
coordinate_workers() {
    echo -e "${CYAN}🎯 Worker間調整${NC}"
    echo ""
    
    local coordination_message="
🤝 【Worker間調整】$(date '+%Y-%m-%d %H:%M')

BOSSより調整指示：

各Workerは以下の点で連携を強化してください：

🎨 Worker1 (UI/UX) ⟷ ⚙️ Worker2 (Backend)：
- API仕様の確認・調整
- データ形式の統一
- エラーハンドリングの連携

⚙️ Worker2 (Backend) ⟷ 🧪 Worker3 (Test)：
- テストデータの準備
- テスト環境の構築
- パフォーマンステストの計画

🎨 Worker1 (UI/UX) ⟷ 🧪 Worker3 (Test)：
- UI/UXテストシナリオの作成
- アクセシビリティテストの実施
- ユーザビリティテストの計画

📋 調整方法：
1. 直接的な情報共有
2. 共通ドキュメントの活用
3. 必要に応じてBOSSへエスカレーション

🎯 目標：
各専門分野の知見を統合し、最高品質の成果物を創造する

積極的な連携をお願いします！

---
BOSS
    "
    
    for worker in worker1 worker2 worker3; do
        send_instruction_to_worker "$worker" "$coordination_message"
    done
    
    echo -e "${GREEN}✅ Worker間調整指示送信完了${NC}"
}

# PRESIDENT報告（エスカレーション）
escalate_to_president() {
    echo -e "${CYAN}🎯 PRESIDENT報告（エスカレーション）${NC}"
    echo ""
    
    echo -e "${YELLOW}PRESIDENTへの報告内容を入力してください${NC}"
    echo -e "${YELLOW}（複数行可能。終了するには空行でEnter）${NC}"
    echo ""
    
    local report_content=""
    local line=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            break
        fi
        report_content="${report_content}${line}\n"
    done
    
    if [ -z "$report_content" ]; then
        echo -e "${YELLOW}⚠️  報告内容が入力されませんでした${NC}"
        exit 1
    fi
    
    local president_report="
📊 【BOSSからPRESIDENT報告】$(date '+%Y-%m-%d %H:%M')

PRESIDENT様

BOSSより重要事項を報告いたします：

$(echo -e "$report_content")

📋 現在の状況：
- Worker1 (UI/UX): 配布済み
- Worker2 (Backend): 配布済み  
- Worker3 (Test): 配布済み

🎯 BOSSとしての判断・対応：
上記事項についてPRESIDENTの指示・承認を求めます。

チーム運営に関するご指導をお願いいたします。

---
BOSS
    "
    
    # PRESIDENTに送信（tmux pane 0.0）
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        tmux send-keys -t "$SESSION_NAME:0.0" "echo '📊 BOSSからの報告:'" C-m
        echo "$president_report" | while IFS= read -r line; do
            tmux send-keys -t "$SESSION_NAME:0.0" "echo '$line'" C-m
        done
        echo -e "${GREEN}✅ PRESIDENT報告送信完了${NC}"
    else
        # ファイルに保存
        local report_file="$CLAUDE_SYSTEM_ROOT/reports/boss_to_president_$(date +%Y%m%d_%H%M%S).md"
        mkdir -p "$(dirname "$report_file")"
        echo "$president_report" > "$report_file"
        echo -e "${GREEN}📝 PRESIDENT報告保存: $report_file${NC}"
    fi
}

# メイン処理
main() {
    case "${1:-}" in
        "analyze")
            analyze_planlist_as_boss
            ;;
        "assign")
            if [ -z "${2:-}" ]; then
                auto_assign_as_boss
            else
                assign_specific "$2" "$3"
            fi
            ;;
        "reassign")
            echo -e "${CYAN}🔄 分配再調整機能（開発予定）${NC}"
            ;;
        "instruct")
            instruct_worker "$2"
            ;;
        "broadcast")
            broadcast_instruction
            ;;
        "meeting")
            hold_team_meeting
            ;;
        "check")
            check_progress
            ;;
        "review")
            review_worker "$2"
            ;;
        "feedback")
            echo -e "${CYAN}📝 フィードバック機能（開発予定）${NC}"
            ;;
        "coordinate")
            coordinate_workers
            ;;
        "support")
            echo -e "${CYAN}🤝 個別支援機能（開発予定）${NC}"
            ;;
        "escalate")
            escalate_to_president
            ;;
        "help"|"-h"|"--help")
            show_usage
            ;;
        *)
            show_boss_logo
            echo -e "${RED}❌ 不正なコマンド: ${1:-}${NC}"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@" 