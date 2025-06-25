#!/bin/bash

# Progress Tracker - 進捗管理・追跡システム
# 各チームの進捗を追跡し、比較分析を行うシステム

set -e

# 設定
SESSION_NAME="multiagent"
LOGS_DIR="../logs"
REPORTS_DIR="../reports"
PROGRESS_LOG="$LOGS_DIR/progress_tracking.log"

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
NC='\033[0m'

# ロゴ表示
show_logo() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                   PROGRESS TRACKER                            ║"
    echo "║                  進捗管理・追跡システム                        ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# tmuxセッション確認
check_session() {
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}エラー: tmuxセッション '$SESSION_NAME' が見つかりません${NC}"
        echo "まず './setup-multiagent.sh' を実行してセッションを作成してください"
        return 1
    fi
}

# 進捗報告要求
request_progress_report() {
    local target_team="$1"
    local report_type="${2:-standard}"
    
    check_session || return 1
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 標準進捗報告フォーマット
    local standard_request="【進捗報告要求】プレジデントです。以下の形式で進捗を報告してください：

## 📊 進捗状況
- **完了率**: __% 
- **現在のフェーズ**: _______
- **完了したタスク**: 
  - 
  - 
- **進行中のタスク**:
  - 
  - 

## 🎯 技術的評価
- **実装難易度**: ★★★☆☆ (5段階)
- **技術的リスク**: ★★☆☆☆ (5段階)
- **推奨度**: ★★★★☆ (5段階)

## 📝 詳細報告
### 完了した作業
- 

### 現在の課題
- 

### 次のステップ
- 

### 必要なサポート
- 

## ⏰ スケジュール
- **予定完了日**: ____年__月__日
- **遅延リスク**: あり/なし
- **遅延理由**: 

報告期限: 2時間以内
よろしくお願いいたします。"

    # 詳細技術報告フォーマット
    local technical_request="【技術詳細報告要求】以下の技術的観点で詳細報告をお願いします：

## 🔧 技術仕様
### アーキテクチャ設計
- **採用技術**: 
- **設計パターン**: 
- **データフロー**: 

### 実装詳細
- **主要コンポーネント**: 
- **API設計**: 
- **データベース設計**: 

## 📈 パフォーマンス評価
- **処理速度**: 
- **スケーラビリティ**: 
- **メモリ使用量**: 

## 🛡️ セキュリティ・品質
- **セキュリティ対策**: 
- **テスト戦略**: 
- **エラーハンドリング**: 

## 🚀 運用・保守性
- **デプロイ方法**: 
- **監視・ログ**: 
- **保守性評価**: 

報告期限: 4時間以内"

    # 比較分析用報告フォーマット
    local comparison_request="【比較分析用報告要求】他チームとの比較分析のため、以下の項目で報告してください：

## 📊 定量評価 (1-5点で評価)
| 項目 | 評価 | 理由 |
|------|------|------|
| 実装難易度 | __点 | |
| 開発効率 | __点 | |
| 保守性 | __点 | |
| 拡張性 | __点 | |
| セキュリティ | __点 | |
| パフォーマンス | __点 | |

## 💡 強み・弱み分析
### 強み
- 
- 
- 

### 弱み
- 
- 
- 

## 🎯 推奨理由
なぜこの方式案を推奨するか（3つのポイント）：
1. 
2. 
3. 

## ⚠️ 懸念事項
- 
- 

報告期限: 3時間以内"

    # 報告フォーマット選択
    local request_message
    case "$report_type" in
        standard|std) request_message="$standard_request" ;;
        technical|tech) request_message="$technical_request" ;;
        comparison|comp) request_message="$comparison_request" ;;
        *) request_message="$standard_request" ;;
    esac
    
    # 送信先決定
    if [[ -n "$target_team" ]]; then
        local team_name
        case "$target_team" in
            1|dev-a|DEV-A) team_name="DEV-A"; target_team="1" ;;
            2|dev-b|DEV-B) team_name="DEV-B"; target_team="2" ;;
            3|dev-c|DEV-C) team_name="DEV-C"; target_team="3" ;;
            *) echo -e "${RED}エラー: 無効なチーム番号 '$target_team'${NC}"; return 1 ;;
        esac
        
        echo -e "${GREEN}[$timestamp] ${team_name}に進捗報告要求（$report_type）${NC}"
        tmux send-keys -t "$SESSION_NAME:0.$target_team" "$request_message" Enter
        
        # ログ記録
        echo "[$timestamp] PROGRESS_REQUEST: $report_type -> $team_name" >> "$PROGRESS_LOG"
    else
        echo -e "${GREEN}[$timestamp] 全チームに進捗報告要求（$report_type）${NC}"
        for i in {1..3}; do
            case $i in
                1) team_name="DEV-A" ;;
                2) team_name="DEV-B" ;;
                3) team_name="DEV-C" ;;
            esac
            
            echo -e "${CYAN}${team_name}に送信中...${NC}"
            tmux send-keys -t "$SESSION_NAME:0.$i" "$request_message" Enter
            
            # ログ記録
            echo "[$timestamp] PROGRESS_REQUEST: $report_type -> $team_name" >> "$PROGRESS_LOG"
            sleep 1
        done
    fi
    
    echo -e "${CYAN}進捗報告要求を送信完了${NC}"
}

# フィードバック送信
send_feedback() {
    local target_team="$1"
    local feedback_type="${2:-general}"
    
    check_session || return 1
    
    if [[ -z "$target_team" ]]; then
        echo -e "${RED}使用方法: send_feedback <チーム番号> [feedback_type]${NC}"
        return 1
    fi
    
    # チーム名決定
    local team_name
    case "$target_team" in
        1|dev-a|DEV-A) team_name="DEV-A"; target_team="1" ;;
        2|dev-b|DEV-B) team_name="DEV-B"; target_team="2" ;;
        3|dev-c|DEV-C) team_name="DEV-C"; target_team="3" ;;
        *) echo -e "${RED}エラー: 無効なチーム番号 '$target_team'${NC}"; return 1 ;;
    esac
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # フィードバックテンプレート
    local feedback_template="【フィードバック】プレジデントです。進捗報告ありがとうございました。

## 📋 評価結果
### 評価できる点
- 
- 
- 

### 改善提案
- 
- 
- 

### 次のアクション
- 
- 
- 

## 🎯 重点項目
今後特に注力していただきたい項目：
1. 
2. 
3. 

## 📅 次回報告
次回報告予定: ____年__月__日 __時
報告内容: 

引き続きよろしくお願いいたします。"
    
    echo -e "${GREEN}[$timestamp] ${team_name}にフィードバック送信中...${NC}"
    echo -e "${YELLOW}以下のテンプレートを編集して送信してください：${NC}"
    echo ""
    echo "$feedback_template"
    echo ""
    read -p "上記テンプレートを送信しますか？ (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        tmux send-keys -t "$SESSION_NAME:0.$target_team" "$feedback_template" Enter
        echo "[$timestamp] FEEDBACK: $feedback_type -> $team_name" >> "$PROGRESS_LOG"
        echo -e "${CYAN}フィードバックを${team_name}に送信しました${NC}"
    else
        echo -e "${YELLOW}フィードバック送信をキャンセルしました${NC}"
    fi
}

# 比較分析レポート生成
generate_comparison_report() {
    local date_str=$(date '+%Y%m%d_%H%M')
    local report_file="$REPORTS_DIR/progress_comparison_$date_str.md"
    
    echo -e "${YELLOW}=== 比較分析レポート生成 ===${NC}"
    
    cat > "$report_file" << EOF
# 進捗比較分析レポート
生成日時: $(date '+%Y年%m月%d日 %H:%M:%S')

## 📊 概要
各開発チームの進捗状況を比較分析し、プロジェクト全体の状況を評価します。

## 🎯 チーム別進捗状況

### DEV-A チーム（方式案A）
#### 進捗状況
- **完了率**: __%
- **現在フェーズ**: 
- **主要成果物**: 

#### 技術評価
| 項目 | 評価 | コメント |
|------|------|----------|
| 実装難易度 | ★★★☆☆ | |
| 技術的リスク | ★★☆☆☆ | |
| 推奨度 | ★★★★☆ | |

#### 強み・課題
**強み**:
- 
- 

**課題**:
- 
- 

---

### DEV-B チーム（方式案B）
#### 進捗状況
- **完了率**: __%
- **現在フェーズ**: 
- **主要成果物**: 

#### 技術評価
| 項目 | 評価 | コメント |
|------|------|----------|
| 実装難易度 | ★★★☆☆ | |
| 技術的リスク | ★★☆☆☆ | |
| 推奨度 | ★★★★☆ | |

#### 強み・課題
**強み**:
- 
- 

**課題**:
- 
- 

---

### DEV-C チーム（方式案C）
#### 進捗状況
- **完了率**: __%
- **現在フェーズ**: 
- **主要成果物**: 

#### 技術評価
| 項目 | 評価 | コメント |
|------|------|----------|
| 実装難易度 | ★★★☆☆ | |
| 技術的リスク | ★★☆☆☆ | |
| 推奨度 | ★★★★☆ | |

#### 強み・課題
**強み**:
- 
- 

**課題**:
- 
- 

## 📈 横断比較分析

### 進捗速度比較
| チーム | 完了率 | 予定との差 | 評価 |
|--------|--------|------------|------|
| DEV-A | __% | | |
| DEV-B | __% | | |
| DEV-C | __% | | |

### 技術的実現性比較
| 項目 | DEV-A | DEV-B | DEV-C | 最優秀 |
|------|-------|-------|-------|--------|
| 実装難易度 | | | | |
| 技術的リスク | | | | |
| 拡張性 | | | | |
| 保守性 | | | | |
| パフォーマンス | | | | |

## 🎯 プレジデント総合評価

### 現時点での推奨方式案
**推奨**: 方式案_
**理由**:
1. 
2. 
3. 

### 各チームへの指示事項
#### DEV-A向け
- 
- 

#### DEV-B向け
- 
- 

#### DEV-C向け
- 
- 

### 今後のマイルストーン
| 日付 | マイルストーン | 担当 | 重要度 |
|------|----------------|------|--------|
| | | | |
| | | | |
| | | | |

## 📋 次回レビュー計画
- **次回レビュー日**: ____年__月__日
- **レビュー形式**: 
- **重点項目**: 
- **期待される成果物**: 

---
*このレポートは自動生成されたテンプレートです。各項目を実際の進捗状況で更新してください。*
EOF
    
    echo -e "${GREEN}比較分析レポートを生成しました: $report_file${NC}"
    echo -e "${CYAN}各チームの実際の進捗データを基に内容を更新してください${NC}"
}

# 定期チェックスケジューラー
schedule_regular_check() {
    local interval="${1:-daily}"
    
    echo -e "${YELLOW}=== 定期チェックスケジューラー ===${NC}"
    
    case "$interval" in
        hourly)
            echo -e "${GREEN}1時間ごとの進捗チェックを設定${NC}"
            echo "0 * * * * cd $(pwd) && ./progress-tracker.sh request all standard" > /tmp/progress_cron
            ;;
        daily)
            echo -e "${GREEN}日次進捗チェックを設定${NC}"
            echo "0 9 * * * cd $(pwd) && ./progress-tracker.sh request all standard" > /tmp/progress_cron
            echo "0 17 * * * cd $(pwd) && ./progress-tracker.sh request all standard" >> /tmp/progress_cron
            ;;
        weekly)
            echo -e "${GREEN}週次詳細レビューを設定${NC}"
            echo "0 10 * * 1 cd $(pwd) && ./progress-tracker.sh request all comparison" > /tmp/progress_cron
            ;;
        *)
            echo -e "${RED}無効な間隔: $interval${NC}"
            echo "有効な値: hourly, daily, weekly"
            return 1
            ;;
    esac
    
    echo -e "${CYAN}cron設定ファイルを作成しました: /tmp/progress_cron${NC}"
    echo -e "${YELLOW}以下のコマンドでcronに登録してください：${NC}"
    echo "crontab /tmp/progress_cron"
}

# 進捗ログ表示
show_progress_logs() {
    local log_type="${1:-all}"
    
    echo -e "${YELLOW}=== 進捗ログ ===${NC}"
    
    if [[ ! -f "$PROGRESS_LOG" ]]; then
        echo "進捗ログが見つかりません"
        return 1
    fi
    
    case "$log_type" in
        request|req)
            echo -e "${CYAN}進捗報告要求ログ:${NC}"
            grep "PROGRESS_REQUEST" "$PROGRESS_LOG" | tail -10
            ;;
        feedback|fb)
            echo -e "${CYAN}フィードバックログ:${NC}"
            grep "FEEDBACK" "$PROGRESS_LOG" | tail -10
            ;;
        all)
            echo -e "${CYAN}全進捗ログ（最新20件）:${NC}"
            tail -20 "$PROGRESS_LOG"
            ;;
        *)
            echo -e "${RED}無効なログタイプ: $log_type${NC}"
            echo "有効な値: request, feedback, all"
            ;;
    esac
}

# 使用方法表示
show_usage() {
    echo -e "${CYAN}Progress Tracker 使用方法:${NC}"
    echo ""
    echo -e "${WHITE}基本コマンド:${NC}"
    echo "  ./progress-tracker.sh request [チーム] [タイプ]  # 進捗報告要求"
    echo "  ./progress-tracker.sh feedback <チーム>         # フィードバック送信"
    echo "  ./progress-tracker.sh compare                   # 比較分析レポート生成"
    echo "  ./progress-tracker.sh schedule [間隔]           # 定期チェック設定"
    echo "  ./progress-tracker.sh logs [タイプ]             # ログ表示"
    echo ""
    echo -e "${WHITE}報告タイプ:${NC}"
    echo "  standard   - 標準進捗報告"
    echo "  technical  - 技術詳細報告"
    echo "  comparison - 比較分析用報告"
    echo ""
    echo -e "${WHITE}例:${NC}"
    echo "  ./progress-tracker.sh request 1 standard       # DEV-Aに標準報告要求"
    echo "  ./progress-tracker.sh request all technical    # 全チームに技術報告要求"
    echo "  ./progress-tracker.sh feedback 2               # DEV-Bにフィードバック"
    echo "  ./progress-tracker.sh schedule daily           # 日次チェック設定"
}

# メイン処理
main() {
    show_logo
    
    case "${1:-help}" in
        request|req)
            request_progress_report "$2" "$3"
            ;;
        feedback|fb)
            send_feedback "$2" "$3"
            ;;
        compare|comp)
            generate_comparison_report
            ;;
        schedule|sched)
            schedule_regular_check "$2"
            ;;
        logs|log)
            show_progress_logs "$2"
            ;;
        help|--help|-h)
            show_usage
            ;;
        *)
            echo -e "${RED}不明なコマンド: $1${NC}"
            show_usage
            ;;
    esac
}

# スクリプト実行
main "$@" 