#!/bin/bash

# President Controller - 統合管理システム
# プレジデント/マネージャーがチームに個別指示し、報告を管理するシステム

set -e

# 設定
SESSION_NAME="multiagent"
LOGS_DIR="../logs"
REPORTS_DIR="../reports"

# ディレクトリ作成
mkdir -p "$LOGS_DIR"
mkdir -p "$REPORTS_DIR"

# 色設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ロゴ表示
show_logo() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    PRESIDENT CONTROLLER                       ║"
    echo "║                  統合チーム管理システム                        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# tmuxセッション存在確認
check_session() {
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}エラー: tmuxセッション '$SESSION_NAME' が見つかりません${NC}"
        echo "まず './setup-multiagent.sh' を実行してセッションを作成してください"
        exit 1
    fi
}

# チームメンバー一覧
list_team_members() {
    echo -e "${YELLOW}=== チームメンバー一覧 ===${NC}"
    echo -e "${WHITE}0:${NC} CEO (あなた)"
    echo -e "${WHITE}1:${NC} DEV-A (開発チームA)"
    echo -e "${WHITE}2:${NC} DEV-B (開発チームB)" 
    echo -e "${WHITE}3:${NC} DEV-C (開発チームC)"
    echo ""
}

# 個別指示送信
send_individual_instruction() {
    local target_member="$1"
    local instruction="$2"
    
    if [[ -z "$target_member" || -z "$instruction" ]]; then
        echo -e "${RED}使用方法: send_individual_instruction <メンバー番号> <指示内容>${NC}"
        return 1
    fi
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_file="$LOGS_DIR/instructions_$(date '+%Y%m%d').log"
    
    case "$target_member" in
        1|dev-a|DEV-A)
            target_member="1"
            member_name="DEV-A"
            ;;
        2|dev-b|DEV-B)
            target_member="2"
            member_name="DEV-B"
            ;;
        3|dev-c|DEV-C)
            target_member="3"
            member_name="DEV-C"
            ;;
        *)
            echo -e "${RED}エラー: 無効なメンバー番号 '$target_member'${NC}"
            echo "有効な値: 1(dev-a), 2(dev-b), 3(dev-c)"
            return 1
            ;;
    esac
    
    # 指示をtmuxペインに送信
    echo -e "${GREEN}[$timestamp] プレジデントから$member_name への指示:${NC}"
    echo -e "${WHITE}$instruction${NC}"
    
    tmux send-keys -t "$SESSION_NAME:0.$target_member" "$instruction" Enter
    
    # ログ記録
    echo "[$timestamp] PRESIDENT -> $member_name: $instruction" >> "$log_file"
    
    echo -e "${CYAN}指示を $member_name に送信しました${NC}"
}

# 全体指示送信
send_team_instruction() {
    local instruction="$1"
    
    if [[ -z "$instruction" ]]; then
        echo -e "${RED}使用方法: send_team_instruction <指示内容>${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}=== 全チームへの指示送信 ===${NC}"
    
    for i in {1..3}; do
        case $i in
            1) member_name="DEV-A" ;;
            2) member_name="DEV-B" ;;
            3) member_name="DEV-C" ;;
        esac
        
        echo -e "${GREEN}$member_name に送信中...${NC}"
        send_individual_instruction "$i" "$instruction"
        sleep 1
    done
    
    echo -e "${CYAN}全チームに指示を送信完了${NC}"
}

# 進捗報告要求
request_progress_report() {
    local target_member="$1"
    local report_type="${2:-general}"
    
    local report_request="【進捗報告要求】プレジデントです。以下について報告してください：
1. 現在の作業状況
2. 完了したタスク
3. 進行中のタスク
4. 課題・問題点
5. 次のステップ

報告形式: markdown形式でお願いします。"
    
    if [[ -n "$target_member" ]]; then
        echo -e "${YELLOW}=== $target_member への進捗報告要求 ===${NC}"
        send_individual_instruction "$target_member" "$report_request"
    else
        echo -e "${YELLOW}=== 全チームへの進捗報告要求 ===${NC}"
        send_team_instruction "$report_request"
    fi
}

# 報告書収集
collect_reports() {
    local date_str=$(date '+%Y%m%d')
    local report_file="$REPORTS_DIR/team_reports_$date_str.md"
    
    echo -e "${YELLOW}=== 報告書収集開始 ===${NC}"
    
    cat > "$report_file" << EOF
# チーム進捗報告書
日付: $(date '+%Y年%m月%d日 %H:%M:%S')

## 概要
本日のチーム進捗報告をまとめます。

## DEV-A 報告
- 状況: 
- 進捗: 
- 課題: 
- 次のステップ: 

## DEV-B 報告  
- 状況: 
- 進捗: 
- 課題: 
- 次のステップ: 

## DEV-C 報告
- 状況: 
- 進捗: 
- 課題: 
- 次のステップ: 

## プレジデント分析
### 全体状況評価
- 

### 優先課題
1. 
2. 
3. 

### 次回指示事項
- 

EOF
    
    echo -e "${GREEN}報告書テンプレートを作成: $report_file${NC}"
    echo -e "${CYAN}各チームからの報告を上記ファイルに手動で追记してください${NC}"
}

# 比較分析レポート作成
create_comparison_report() {
    local date_str=$(date '+%Y%m%d')
    local comparison_file="$REPORTS_DIR/comparison_analysis_$date_str.md"
    
    echo -e "${YELLOW}=== 比較分析レポート作成 ===${NC}"
    
    cat > "$comparison_file" << EOF
# 方式案比較分析レポート
作成日: $(date '+%Y年%m月%d日 %H:%M:%S')

## 分析対象
- 方式案A (DEV-A担当)
- 方式案B (DEV-B担当)  
- 方式案C (DEV-C担当)

## 比較項目

### 1. 技術的実現性
| 項目 | DEV-A | DEV-B | DEV-C | 評価 |
|------|-------|-------|-------|------|
| 実装難易度 |  |  |  |  |
| 技術的リスク |  |  |  |  |
| 拡張性 |  |  |  |  |

### 2. 開発効率
| 項目 | DEV-A | DEV-B | DEV-C | 評価 |
|------|-------|-------|-------|------|
| 開発期間 |  |  |  |  |
| リソース要件 |  |  |  |  |
| メンテナンス性 |  |  |  |  |

### 3. 品質・性能
| 項目 | DEV-A | DEV-B | DEV-C | 評価 |
|------|-------|-------|-------|------|
| 安定性 |  |  |  |  |
| パフォーマンス |  |  |  |  |
| ユーザビリティ |  |  |  |  |

## プレジデント総合評価

### 推奨方式案
方式案_: _______________

### 理由
1. 
2. 
3. 

### 改善提案
- DEV-A向け: 
- DEV-B向け: 
- DEV-C向け: 

### 次のアクション
1. 
2. 
3. 

EOF
    
    echo -e "${GREEN}比較分析レポートテンプレートを作成: $comparison_file${NC}"
    echo -e "${CYAN}各チームの実績を基に分析を記入してください${NC}"
}

# ログ閲覧
view_logs() {
    local log_type="$1"
    
    case "$log_type" in
        instructions|inst)
            echo -e "${YELLOW}=== 指示ログ ===${NC}"
            if ls "$LOGS_DIR"/instructions_*.log 1> /dev/null 2>&1; then
                tail -20 "$LOGS_DIR"/instructions_*.log
            else
                echo "指示ログが見つかりません"
            fi
            ;;
        reports|rep)
            echo -e "${YELLOW}=== 報告書一覧 ===${NC}"
            if ls "$REPORTS_DIR"/*.md 1> /dev/null 2>&1; then
                ls -la "$REPORTS_DIR"/*.md
            else
                echo "報告書が見つかりません"
            fi
            ;;
        all)
            view_logs instructions
            echo ""
            view_logs reports
            ;;
        *)
            echo -e "${RED}使用方法: view_logs [instructions|reports|all]${NC}"
            ;;
    esac
}

# インタラクティブメニュー
interactive_menu() {
    while true; do
        clear
        show_logo
        list_team_members
        
        echo -e "${WHITE}=== プレジデントメニュー ===${NC}"
        echo "1. 個別指示送信"
        echo "2. 全体指示送信"
        echo "3. 進捗報告要求"
        echo "4. 報告書収集"
        echo "5. 比較分析レポート作成"
        echo "6. ログ閲覧"
        echo "7. tmuxセッション表示"
        echo "0. 終了"
        echo ""
        
        read -p "選択してください (0-7): " choice
        
        case $choice in
            1)
                echo ""
                read -p "送信先メンバー (1:DEV-A, 2:DEV-B, 3:DEV-C): " target
                read -p "指示内容: " instruction
                send_individual_instruction "$target" "$instruction"
                read -p "Enterキーで続行..."
                ;;
            2)
                echo ""
                read -p "全体指示内容: " instruction
                send_team_instruction "$instruction"
                read -p "Enterキーで続行..."
                ;;
            3)
                echo ""
                read -p "対象メンバー (1-3, または空白で全体): " target
                request_progress_report "$target"
                read -p "Enterキーで続行..."
                ;;
            4)
                collect_reports
                read -p "Enterキーで続行..."
                ;;
            5)
                create_comparison_report
                read -p "Enterキーで続行..."
                ;;
            6)
                echo ""
                read -p "ログタイプ (instructions/reports/all): " log_type
                view_logs "$log_type"
                read -p "Enterキーで続行..."
                ;;
            7)
                echo -e "${CYAN}tmuxセッションに接続中...${NC}"
                tmux attach-session -t "$SESSION_NAME"
                ;;
            0)
                echo -e "${GREEN}プレジデントコントローラーを終了します${NC}"
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
    # 引数がある場合はコマンドラインモード
    if [[ $# -gt 0 ]]; then
        case "$1" in
            send)
                shift
                send_individual_instruction "$@"
                ;;
            team)
                shift
                send_team_instruction "$@"
                ;;
            report)
                shift
                request_progress_report "$@"
                ;;
            collect)
                collect_reports
                ;;
            compare)
                create_comparison_report
                ;;
            logs)
                shift
                view_logs "$@"
                ;;
            help|--help|-h)
                show_usage
                ;;
            *)
                echo -e "${RED}不明なコマンド: $1${NC}"
                show_usage
                ;;
        esac
    else
        # インタラクティブモード
        check_session
        interactive_menu
    fi
}

# 使用方法表示
show_usage() {
    echo -e "${CYAN}プレジデントコントローラー使用方法:${NC}"
    echo ""
    echo -e "${WHITE}インタラクティブモード:${NC}"
    echo "  ./president-controller.sh"
    echo ""
    echo -e "${WHITE}コマンドラインモード:${NC}"
    echo "  ./president-controller.sh send <メンバー> <指示>"
    echo "  ./president-controller.sh team <指示>"
    echo "  ./president-controller.sh report [メンバー]"
    echo "  ./president-controller.sh collect"
    echo "  ./president-controller.sh compare"
    echo "  ./president-controller.sh logs [instructions|reports|all]"
    echo ""
    echo -e "${WHITE}例:${NC}"
    echo "  ./president-controller.sh send 1 'API設計を開始してください'"
    echo "  ./president-controller.sh team '本日の進捗を報告してください'"
    echo "  ./president-controller.sh report 2"
}

# スクリプト実行
main "$@" 