#!/bin/bash
# ==============================================================================
# Master Controller - 統合運用システム
# ==============================================================================
# Description: 全機能を統合したマスターコントローラー
# Usage: master-controller.sh [start|stop|status|setup|team|worktree]
# Dependencies: tmux, git, curl
# ==============================================================================

set -e

# 設定
SESSION_NAME="multiagent"
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'

# ASCII Artロゴ
show_master_logo() {
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║    ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗                       ║
║    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗                      ║
║    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝                      ║
║    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗                      ║
║    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║                      ║
║    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝                      ║
║                                                                               ║
║                    CONTROLLER                                                 ║
║                                                                               ║
║               Claude Multi-Agent System 統合管理システム                      ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${WHITE}Version 2.0 - Complete Team Development Suite${NC}"
    echo ""
}

# システム状態確認
check_system_status() {
    echo -e "${YELLOW}=== システム状態確認 ===${NC}"
    
    # tmuxセッション確認
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${GREEN}✅ tmuxセッション '$SESSION_NAME' 実行中${NC}"
        
        # ペイン数確認
        local pane_count=$(tmux list-panes -t "$SESSION_NAME" | wc -l)
        echo -e "${GREEN}✅ ペイン数: $pane_count${NC}"
        
        if [[ "$pane_count" -eq 4 ]]; then
            echo -e "${GREEN}✅ 4ペイン構成正常${NC}"
        else
            echo -e "${YELLOW}⚠️  ペイン数が4ではありません${NC}"
        fi
    else
        echo -e "${RED}❌ tmuxセッション '$SESSION_NAME' が見つかりません${NC}"
        echo -e "${YELLOW}   './setup-multiagent.sh' を実行してセッションを作成してください${NC}"
    fi
    
    # スクリプトファイル確認
    local scripts=("setup-multiagent.sh" "president-controller.sh" "plan-distributor.sh" "progress-tracker.sh")
    echo ""
    echo -e "${YELLOW}スクリプトファイル確認:${NC}"
    
    for script in "${scripts[@]}"; do
        if [[ -f "$SCRIPTS_DIR/$script" && -x "$SCRIPTS_DIR/$script" ]]; then
            echo -e "${GREEN}✅ $script${NC}"
        else
            echo -e "${RED}❌ $script (見つからないか実行権限なし)${NC}"
        fi
    done
    
    # ディレクトリ確認
    echo ""
    echo -e "${YELLOW}ディレクトリ構成:${NC}"
    
    local dirs=("../logs" "../reports")
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            echo -e "${GREEN}✅ $dir${NC}"
        else
            echo -e "${YELLOW}⚠️  $dir (作成されます)${NC}"
            mkdir -p "$dir"
        fi
    done
    
    echo ""
}

# クイックセットアップ
quick_setup() {
    echo -e "${CYAN}=== クイックセットアップ ===${NC}"
    echo ""
    
    echo -e "${GREEN}1. tmux環境セットアップ中...${NC}"
    if [[ -f "$SCRIPTS_DIR/setup-multiagent.sh" ]]; then
        "$SCRIPTS_DIR/setup-multiagent.sh"
    else
        echo -e "${RED}エラー: setup-multiagent.sh が見つかりません${NC}"
        return 1
    fi
    
    echo ""
    echo -e "${GREEN}2. Claude AIエージェント起動中...${NC}"
    if [[ -f "$SCRIPTS_DIR/quick-start-multiagent.sh" ]]; then
        "$SCRIPTS_DIR/quick-start-multiagent.sh"
    else
        echo -e "${YELLOW}警告: quick-start-multiagent.sh が見つかりません${NC}"
    fi
    
    echo ""
    echo -e "${CYAN}クイックセットアップ完了！${NC}"
    echo -e "${WHITE}次のステップ: ${CYAN}tmux attach-session -t $SESSION_NAME${NC}"
}

# プレジデント機能メニュー
president_menu() {
    while true; do
        clear
        echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║                    PRESIDENT FUNCTIONS                        ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${WHITE}1.${NC} 個別指示送信"
        echo -e "${WHITE}2.${NC} 全体指示送信"
        echo -e "${WHITE}3.${NC} 進捗報告要求"
        echo -e "${WHITE}4.${NC} 報告書収集"
        echo -e "${WHITE}5.${NC} 比較分析レポート作成"
        echo -e "${WHITE}6.${NC} ログ閲覧"
        echo -e "${WHITE}7.${NC} プレジデントコントローラー起動"
        echo -e "${WHITE}0.${NC} メインメニューに戻る"
        echo ""
        
        read -p "選択してください (0-7): " choice
        
        case $choice in
            1)
                echo ""
                read -p "送信先 (1:DEV-A, 2:DEV-B, 3:DEV-C): " target
                read -p "指示内容: " instruction
                "$SCRIPTS_DIR/president-controller.sh" send "$target" "$instruction"
                read -p "Enterキーで続行..."
                ;;
            2)
                echo ""
                read -p "全体指示内容: " instruction
                "$SCRIPTS_DIR/president-controller.sh" team "$instruction"
                read -p "Enterキーで続行..."
                ;;
            3)
                echo ""
                read -p "対象 (1-3, または空白で全体): " target
                "$SCRIPTS_DIR/president-controller.sh" report "$target"
                read -p "Enterキーで続行..."
                ;;
            4)
                "$SCRIPTS_DIR/president-controller.sh" collect
                read -p "Enterキーで続行..."
                ;;
            5)
                "$SCRIPTS_DIR/president-controller.sh" compare
                read -p "Enterキーで続行..."
                ;;
            6)
                echo ""
                read -p "ログタイプ (instructions/reports/all): " log_type
                "$SCRIPTS_DIR/president-controller.sh" logs "$log_type"
                read -p "Enterキーで続行..."
                ;;
            7)
                echo -e "${CYAN}プレジデントコントローラーを起動中...${NC}"
                "$SCRIPTS_DIR/president-controller.sh"
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}無効な選択です${NC}"
                read -p "Enterキーで続行..."
                ;;
        esac
    done
}

# 方式案管理メニュー
plan_management_menu() {
    while true; do
        clear
        echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║                    PLAN MANAGEMENT                            ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${WHITE}1.${NC} 方式案一覧表示"
        echo -e "${WHITE}2.${NC} 個別方式案配布"
        echo -e "${WHITE}3.${NC} 全方式案自動配布"
        echo -e "${WHITE}4.${NC} 配布履歴表示"
        echo -e "${WHITE}5.${NC} サンプルplanlist.md作成"
        echo -e "${WHITE}0.${NC} メインメニューに戻る"
        echo ""
        
        read -p "選択してください (0-5): " choice
        
        case $choice in
            1)
                "$SCRIPTS_DIR/plan-distributor.sh" list
                read -p "Enterキーで続行..."
                ;;
            2)
                echo ""
                read -p "方式案番号: " plan_num
                read -p "配布先 (1:DEV-A, 2:DEV-B, 3:DEV-C): " target
                "$SCRIPTS_DIR/plan-distributor.sh" distribute "$plan_num" "$target"
                read -p "Enterキーで続行..."
                ;;
            3)
                "$SCRIPTS_DIR/plan-distributor.sh" auto
                read -p "Enterキーで続行..."
                ;;
            4)
                "$SCRIPTS_DIR/plan-distributor.sh" history
                read -p "Enterキーで続行..."
                ;;
            5)
                "$SCRIPTS_DIR/plan-distributor.sh" sample
                read -p "Enterキーで続行..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}無効な選択です${NC}"
                read -p "Enterキーで続行..."
                ;;
        esac
    done
}

# 進捗管理メニュー
progress_management_menu() {
    while true; do
        clear
        echo -e "${PURPLE}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${PURPLE}║                  PROGRESS MANAGEMENT                          ║${NC}"
        echo -e "${PURPLE}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${WHITE}1.${NC} 標準進捗報告要求"
        echo -e "${WHITE}2.${NC} 技術詳細報告要求"
        echo -e "${WHITE}3.${NC} 比較分析用報告要求"
        echo -e "${WHITE}4.${NC} フィードバック送信"
        echo -e "${WHITE}5.${NC} 比較分析レポート生成"
        echo -e "${WHITE}6.${NC} 進捗ログ表示"
        echo -e "${WHITE}7.${NC} 定期チェック設定"
        echo -e "${WHITE}0.${NC} メインメニューに戻る"
        echo ""
        
        read -p "選択してください (0-7): " choice
        
        case $choice in
            1)
                echo ""
                read -p "対象 (1-3, または空白で全体): " target
                "$SCRIPTS_DIR/progress-tracker.sh" request "$target" standard
                read -p "Enterキーで続行..."
                ;;
            2)
                echo ""
                read -p "対象 (1-3, または空白で全体): " target
                "$SCRIPTS_DIR/progress-tracker.sh" request "$target" technical
                read -p "Enterキーで続行..."
                ;;
            3)
                echo ""
                read -p "対象 (1-3, または空白で全体): " target
                "$SCRIPTS_DIR/progress-tracker.sh" request "$target" comparison
                read -p "Enterキーで続行..."
                ;;
            4)
                echo ""
                read -p "対象チーム (1:DEV-A, 2:DEV-B, 3:DEV-C): " target
                "$SCRIPTS_DIR/progress-tracker.sh" feedback "$target"
                read -p "Enterキーで続行..."
                ;;
            5)
                "$SCRIPTS_DIR/progress-tracker.sh" compare
                read -p "Enterキーで続行..."
                ;;
            6)
                echo ""
                read -p "ログタイプ (request/feedback/all): " log_type
                "$SCRIPTS_DIR/progress-tracker.sh" logs "$log_type"
                read -p "Enterキーで続行..."
                ;;
            7)
                echo ""
                read -p "間隔 (hourly/daily/weekly): " interval
                "$SCRIPTS_DIR/progress-tracker.sh" schedule "$interval"
                read -p "Enterキーで続行..."
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}無効な選択です${NC}"
                read -p "Enterキーで続行..."
                ;;
        esac
    done
}

# ワンライナーモード
oneliner_mode() {
    local command="$1"
    shift
    
    case "$command" in
        setup)
            quick_setup
            ;;
        attach)
            tmux attach-session -t "$SESSION_NAME"
            ;;
        send)
            "$SCRIPTS_DIR/president-controller.sh" send "$@"
            ;;
        team)
            "$SCRIPTS_DIR/president-controller.sh" team "$@"
            ;;
        report)
            "$SCRIPTS_DIR/president-controller.sh" report "$@"
            ;;
        distribute)
            "$SCRIPTS_DIR/plan-distributor.sh" distribute "$@"
            ;;
        auto-dist)
            "$SCRIPTS_DIR/plan-distributor.sh" auto
            ;;
        progress)
            "$SCRIPTS_DIR/progress-tracker.sh" request "$@"
            ;;
        compare)
            "$SCRIPTS_DIR/progress-tracker.sh" compare
            ;;
        status)
            check_system_status
            ;;
        *)
            echo -e "${RED}不明なワンライナーコマンド: $command${NC}"
            show_oneliner_help
            ;;
    esac
}

# ワンライナーヘルプ
show_oneliner_help() {
    echo -e "${CYAN}ワンライナーモード使用方法:${NC}"
    echo ""
    echo -e "${WHITE}システム管理:${NC}"
    echo "  ./master-controller.sh setup              # クイックセットアップ"
    echo "  ./master-controller.sh attach             # tmuxセッション接続"
    echo "  ./master-controller.sh status             # システム状態確認"
    echo ""
    echo -e "${WHITE}プレジデント機能:${NC}"
    echo "  ./master-controller.sh send <チーム> <指示>    # 個別指示"
    echo "  ./master-controller.sh team <指示>            # 全体指示"
    echo "  ./master-controller.sh report [チーム]        # 進捗報告要求"
    echo ""
    echo -e "${WHITE}方式案管理:${NC}"
    echo "  ./master-controller.sh distribute <方式案> <チーム>  # 個別配布"
    echo "  ./master-controller.sh auto-dist                    # 全自動配布"
    echo ""
    echo -e "${WHITE}進捗管理:${NC}"
    echo "  ./master-controller.sh progress [チーム] [タイプ]   # 進捗報告要求"
    echo "  ./master-controller.sh compare                      # 比較分析"
}

# メインメニュー
main_menu() {
    while true; do
        clear
        show_master_logo
        check_system_status
        
        echo -e "${BOLD}${WHITE}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BOLD}${WHITE}║                         MAIN MENU                             ║${NC}"
        echo -e "${BOLD}${WHITE}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        echo -e "${WHITE}🚀 システム管理${NC}"
        echo -e "${WHITE}  1.${NC} クイックセットアップ"
        echo -e "${WHITE}  2.${NC} tmuxセッション表示"
        echo -e "${WHITE}  3.${NC} システム状態確認"
        echo ""
        
        echo -e "${WHITE}👑 プレジデント機能${NC}"
        echo -e "${WHITE}  4.${NC} プレジデント機能メニュー"
        echo ""
        
        echo -e "${WHITE}📋 方式案管理${NC}"
        echo -e "${WHITE}  5.${NC} 方式案管理メニュー"
        echo ""
        
        echo -e "${WHITE}📊 進捗管理${NC}"
        echo -e "${WHITE}  6.${NC} 進捗管理メニュー"
        echo ""
        
        echo -e "${WHITE}📚 その他${NC}"
        echo -e "${WHITE}  7.${NC} ワンライナーヘルプ"
        echo -e "${WHITE}  8.${NC} 全ログ表示"
        echo ""
        
        echo -e "${WHITE}  0.${NC} 終了"
        echo ""
        
        read -p "選択してください (0-8): " choice
        
        case $choice in
            1)
                quick_setup
                read -p "Enterキーで続行..."
                ;;
            2)
                echo -e "${CYAN}tmuxセッションに接続中...${NC}"
                tmux attach-session -t "$SESSION_NAME" 2>/dev/null || echo -e "${RED}セッションが見つかりません${NC}"
                ;;
            3)
                check_system_status
                read -p "Enterキーで続行..."
                ;;
            4)
                president_menu
                ;;
            5)
                plan_management_menu
                ;;
            6)
                progress_management_menu
                ;;
            7)
                show_oneliner_help
                read -p "Enterキーで続行..."
                ;;
            8)
                echo -e "${YELLOW}=== 全ログ表示 ===${NC}"
                find ../logs -name "*.log" -type f 2>/dev/null | while read -r log_file; do
                    echo -e "${CYAN}=== $log_file ===${NC}"
                    tail -5 "$log_file" 2>/dev/null || echo "ログファイルが読み込めません"
                    echo ""
                done
                read -p "Enterキーで続行..."
                ;;
            0)
                echo -e "${GREEN}Master Controller を終了します${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}無効な選択です${NC}"
                read -p "Enterキーで続行..."
                ;;
        esac
    done
}

# メイン処理
main() {
    # 引数がある場合はワンライナーモード
    if [[ $# -gt 0 ]]; then
        oneliner_mode "$@"
    else
        # インタラクティブモード
        main_menu
    fi
}

# スクリプト実行
main "$@" 