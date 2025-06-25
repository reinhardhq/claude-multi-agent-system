#!/bin/bash
# ==============================================================================
# Team Composer - チーム構成システム
# ==============================================================================
# Description: planlist.mdから方式案を分析し適切なWorkerに分配（柔軟フォーマット対応）
# Usage: team-composer.sh [analyze|compose|assign|show|reset]
# Dependencies: git, jq, curl
# ==============================================================================

set -euo pipefail

# 設定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PLANLIST_FILE="$PROJECT_ROOT/planlist.md"
ASSIGNMENTS_DIR="$PROJECT_ROOT/assignments"
REPORTS_DIR="$PROJECT_ROOT/reports"

# 色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_header() {
    echo -e "${PURPLE}$1${NC}"
}

# ヘルプ表示
show_help() {
    cat << EOF
🎯 Team Composer - チーム構成システム (柔軟フォーマット対応版)

使用方法:
    $0 [コマンド] [オプション]

コマンド:
    analyze     planlist.mdを分析して方式案を抽出
    assign      方式案をWorkerに分配
    report      分配レポートを生成
    full        全処理を実行 (analyze + assign + report)
    status      現在の分配状況を表示
    help        このヘルプを表示

オプション:
    --planlist FILE     使用するplanlistファイル (デフォルト: planlist.md)
    --force             既存の分配書を上書き
    --verbose           詳細ログを表示
    --dry-run           実際の処理は行わず、プレビューのみ

例:
    $0 analyze                      # planlist.mdを分析
    $0 assign --force               # 強制的に再分配
    $0 full --verbose               # 全処理を詳細ログ付きで実行
    $0 status                       # 現在の状況を確認

EOF
}

# 初期化
init_directories() {
    log_info "ディレクトリ構造を初期化中..."
    
    mkdir -p "$ASSIGNMENTS_DIR"
    mkdir -p "$REPORTS_DIR"
    
    log_success "ディレクトリ構造を初期化しました"
}

# planlist.mdの存在確認と基本検証
validate_planlist() {
    if [[ ! -f "$PLANLIST_FILE" ]]; then
        log_error "planlist.mdが見つかりません: $PLANLIST_FILE"
        log_info "サンプルファイルをコピーしますか？ (y/n)"
        read -r response
        if [[ "$response" =~ ^[Yy] ]]; then
            if [[ -f "$PROJECT_ROOT/planlist.example.md" ]]; then
                cp "$PROJECT_ROOT/planlist.example.md" "$PLANLIST_FILE"
                log_success "サンプルファイルをコピーしました"
                log_warning "planlist.mdを編集してから再実行してください"
                return 1
            else
                log_error "サンプルファイルも見つかりません"
                return 1
            fi
        else
            return 1
        fi
    fi
    
    # 基本的な構造チェック（柔軟フォーマット対応）
    if ! grep -q "^## 方式案[0-9]" "$PLANLIST_FILE"; then
        log_error "planlist.mdに方式案が見つかりません"
        log_info "正しいフォーマットで記載されているか確認してください"
        return 1
    fi
    
    log_success "planlist.mdの基本検証が完了しました"
    return 0
}

# 必須項目を抽出（固定フォーマット）
extract_required_fields() {
    local approach_num="$1"
    local temp_file="/tmp/approach_${approach_num}_required.txt"
    
    # 方式案セクションを抽出（次の方式案または終端まで）
    if [[ "$approach_num" == "1" ]]; then
        awk "/^## 方式案${approach_num}:/,/^## 方式案2:/{if(/^## 方式案2:/) exit; print}END{if(!found) print}" "$PLANLIST_FILE" > "$temp_file"
    elif [[ "$approach_num" == "2" ]]; then
        awk "/^## 方式案${approach_num}:/,/^## 方式案3:/{if(/^## 方式案3:/) exit; print}END{if(!found) print}" "$PLANLIST_FILE" > "$temp_file"
    else
        awk "/^## 方式案${approach_num}:/,/^## 🔒/{if(/^## 🔒/) exit; print}END{if(!found) print}" "$PLANLIST_FILE" > "$temp_file"
    fi
    
    # 必須項目を抽出
    local overview=""
    local tech_stack=""
    local assigned_worker=""
    local priority=""
    local estimated_hours=""
    local difficulty=""
    
    # 基本情報セクションから必須項目を抽出
    if grep -q "### 🔒 基本情報" "$temp_file"; then
        overview=$(grep "^\*\*概要\*\*:" "$temp_file" | sed 's/\*\*概要\*\*: *//' || echo "未設定")
        tech_stack=$(grep "^\*\*技術スタック\*\*:" "$temp_file" | sed 's/\*\*技術スタック\*\*: *//' || echo "未設定")
        assigned_worker=$(grep "^\*\*担当Worker\*\*:" "$temp_file" | sed 's/\*\*担当Worker\*\*: *//' | sed 's/[[:space:]]*$//' || echo "未指定")
        priority=$(grep "^\*\*優先度\*\*:" "$temp_file" | sed 's/\*\*優先度\*\*: *//' || echo "未設定")
        estimated_hours=$(grep "^\*\*推定工数\*\*:" "$temp_file" | sed 's/\*\*推定工数\*\*: *//' || echo "未設定")
        difficulty=$(grep "^\*\*難易度\*\*:" "$temp_file" | sed 's/\*\*難易度\*\*: *//' || echo "未設定")
    else
        # 基本情報セクションがない場合はファイル全体から抽出を試行
        overview=$(grep "^\*\*概要\*\*:" "$temp_file" | head -n1 | sed 's/\*\*概要\*\*: *//' || echo "未設定")
        tech_stack=$(grep "^\*\*技術スタック\*\*:" "$temp_file" | head -n1 | sed 's/\*\*技術スタック\*\*: *//' || echo "未設定")
        assigned_worker=$(grep "^\*\*担当Worker\*\*:" "$temp_file" | head -n1 | sed 's/\*\*担当Worker\*\*: *//' | sed 's/[[:space:]]*$//' || echo "未指定")
        priority=$(grep "^\*\*優先度\*\*:" "$temp_file" | head -n1 | sed 's/\*\*優先度\*\*: *//' || echo "未設定")
        estimated_hours=$(grep "^\*\*推定工数\*\*:" "$temp_file" | head -n1 | sed 's/\*\*推定工数\*\*: *//' || echo "未設定")
        difficulty=$(grep "^\*\*難易度\*\*:" "$temp_file" | head -n1 | sed 's/\*\*難易度\*\*: *//' || echo "未設定")
    fi
    
    # 結果を出力
    cat << EOF
OVERVIEW="$overview"
TECH_STACK="$tech_stack"
ASSIGNED_WORKER="$assigned_worker"
PRIORITY="$priority"
ESTIMATED_HOURS="$estimated_hours"
DIFFICULTY="$difficulty"
EOF
    
    rm -f "$temp_file"
}

# フリーフォーマット詳細部分を抽出
extract_freeform_details() {
    local approach_num="$1"
    local temp_file="/tmp/approach_${approach_num}_details.txt"
    
    # 方式案セクションを抽出してから詳細部分を抽出
    local section_file="/tmp/approach_${approach_num}_section.txt"
    if [[ "$approach_num" == "1" ]]; then
        awk "/^## 方式案${approach_num}:/,/^## 方式案2:/{if(/^## 方式案2:/) exit; print}END{if(!found) print}" "$PLANLIST_FILE" > "$section_file"
    elif [[ "$approach_num" == "2" ]]; then
        awk "/^## 方式案${approach_num}:/,/^## 方式案3:/{if(/^## 方式案3:/) exit; print}END{if(!found) print}" "$PLANLIST_FILE" > "$section_file"
    else
        awk "/^## 方式案${approach_num}:/,/^## 🔒/{if(/^## 🔒/) exit; print}END{if(!found) print}" "$PLANLIST_FILE" > "$section_file"
    fi
    
    # 方式案詳細セクションを抽出
    awk "/### 💡 方式案詳細/,/^---$/" "$section_file" > "$temp_file"
    
    # フリーフォーマット部分を返す
    if [[ -s "$temp_file" && $(wc -l < "$temp_file") -gt 1 ]]; then
        cat "$temp_file"
    else
        echo "詳細情報が記載されていません"
    fi
    
    # デバッグ用：一時ファイルを保持
    # rm -f "$temp_file" "$section_file"
}

# planlist.mdを分析
analyze_planlist() {
    log_header "📋 planlist.md分析開始"
    
    if ! validate_planlist; then
        return 1
    fi
    
    # プロジェクト概要を抽出
    local project_name=""
    local deadline=""
    local goal=""
    local budget=""
    local team_size=""
    
    if grep -q "### プロジェクト概要" "$PLANLIST_FILE"; then
        project_name=$(grep "^\*\*プロジェクト名\*\*:" "$PLANLIST_FILE" | sed 's/\*\*プロジェクト名\*\*: *//' || echo "未設定")
        deadline=$(grep "^\*\*期限\*\*:" "$PLANLIST_FILE" | sed 's/\*\*期限\*\*: *//' || echo "未設定")
        goal=$(grep "^\*\*目標\*\*:" "$PLANLIST_FILE" | sed 's/\*\*目標\*\*: *//' || echo "未設定")
        budget=$(grep "^\*\*予算\*\*:" "$PLANLIST_FILE" | sed 's/\*\*予算\*\*: *//' || echo "未設定")
        team_size=$(grep "^\*\*チーム規模\*\*:" "$PLANLIST_FILE" | sed 's/\*\*チーム規模\*\*: *//' || echo "未設定")
    fi
    
    log_info "プロジェクト概要:"
    echo "  📛 名前: $project_name"
    echo "  📅 期限: $deadline"
    echo "  🎯 目標: $goal"
    echo "  💰 予算: $budget"
    echo "  👥 チーム規模: $team_size"
    echo ""
    
    # 方式案を検出
    local approaches=($(grep "^## 方式案[0-9]" "$PLANLIST_FILE" | sed 's/^## 方式案\([0-9]\).*/\1/'))
    
    if [[ ${#approaches[@]} -eq 0 ]]; then
        log_error "方式案が見つかりません"
        return 1
    fi
    
    log_info "検出された方式案数: ${#approaches[@]}"
    echo ""
    
    # 各方式案を分析
    for approach in "${approaches[@]}"; do
        log_header "🔍 方式案${approach}を分析中..."
        
        # 必須項目を抽出
        local required_fields
        required_fields=$(extract_required_fields "$approach")
        eval "$required_fields"
        
        # 方式案タイトルを抽出
        local title
        title=$(grep "^## 方式案${approach}:" "$PLANLIST_FILE" | sed "s/^## 方式案${approach}: *//" || echo "タイトル未設定")
        
        echo "  📋 タイトル: $title"
        echo "  📝 概要: $OVERVIEW"
        echo "  🔧 技術スタック: $TECH_STACK"
        echo "  👤 担当Worker: $ASSIGNED_WORKER"
        echo "  ⭐ 優先度: $PRIORITY"
        echo "  ⏱️  推定工数: $ESTIMATED_HOURS"
        echo "  📊 難易度: $DIFFICULTY"
        
        # フリーフォーマット詳細の有無をチェック
        local details_length
        details_length=$(extract_freeform_details "$approach" | wc -l)
        if [[ $details_length -gt 1 ]]; then
            echo "  💡 詳細情報: あり (${details_length}行)"
        else
            echo "  💡 詳細情報: なし"
        fi
        
        echo ""
    done
    
    log_success "planlist.md分析が完了しました"
    
    # 分析結果を保存
    local analysis_file="$REPORTS_DIR/analysis_$(date +%Y%m%d_%H%M%S).md"
    generate_analysis_report "$analysis_file" "${approaches[@]}"
    
    log_info "分析結果を保存しました: $analysis_file"
}

# 分析レポートを生成
generate_analysis_report() {
    local output_file="$1"
    shift
    local approaches=("$@")
    
    cat > "$output_file" << EOF
# 📋 planlist.md分析レポート

**生成日時**: $(date '+%Y-%m-%d %H:%M:%S')  
**分析対象**: $PLANLIST_FILE  
**検出方式案数**: ${#approaches[@]}

---

## 📊 プロジェクト概要

EOF
    
    # プロジェクト概要を追加
    if grep -q "### プロジェクト概要" "$PLANLIST_FILE"; then
        local project_name deadline goal budget team_size
        project_name=$(grep "^\*\*プロジェクト名\*\*:" "$PLANLIST_FILE" | sed 's/\*\*プロジェクト名\*\*: *//' || echo "未設定")
        deadline=$(grep "^\*\*期限\*\*:" "$PLANLIST_FILE" | sed 's/\*\*期限\*\*: *//' || echo "未設定")
        goal=$(grep "^\*\*目標\*\*:" "$PLANLIST_FILE" | sed 's/\*\*目標\*\*: *//' || echo "未設定")
        budget=$(grep "^\*\*予算\*\*:" "$PLANLIST_FILE" | sed 's/\*\*予算\*\*: *//' || echo "未設定")
        team_size=$(grep "^\*\*チーム規模\*\*:" "$PLANLIST_FILE" | sed 's/\*\*チーム規模\*\*: *//' || echo "未設定")
        
        cat >> "$output_file" << EOF
- **プロジェクト名**: $project_name
- **期限**: $deadline
- **目標**: $goal
- **予算**: $budget
- **チーム規模**: $team_size

EOF
    fi
    
    cat >> "$output_file" << EOF
---

## 🔍 方式案詳細分析

EOF
    
    # 各方式案の詳細を追加
    for approach in "${approaches[@]}"; do
        local required_fields title
        required_fields=$(extract_required_fields "$approach")
        eval "$required_fields"
        title=$(grep "^## 方式案${approach}:" "$PLANLIST_FILE" | sed "s/^## 方式案${approach}: *//" || echo "タイトル未設定")
        
        cat >> "$output_file" << EOF
### 方式案${approach}: $title

#### 🔒 必須項目
- **概要**: $OVERVIEW
- **技術スタック**: $TECH_STACK
- **担当Worker**: $ASSIGNED_WORKER
- **優先度**: $PRIORITY
- **推定工数**: $ESTIMATED_HOURS
- **難易度**: $DIFFICULTY

#### 💡 詳細情報
EOF
        
        # フリーフォーマット詳細を追加
        extract_freeform_details "$approach" >> "$output_file"
        
        echo "" >> "$output_file"
        echo "---" >> "$output_file"
        echo "" >> "$output_file"
    done
    
    cat >> "$output_file" << EOF

## 📈 分析サマリー

### 技術スタック分布
EOF
    
    # 技術スタック分布を分析
    for approach in "${approaches[@]}"; do
        local required_fields
        required_fields=$(extract_required_fields "$approach")
        eval "$required_fields"
        echo "- **方式案${approach}**: $TECH_STACK" >> "$output_file"
    done
    
    cat >> "$output_file" << EOF

### Worker分配状況
EOF
    
    # Worker分配状況を分析
    for approach in "${approaches[@]}"; do
        local required_fields
        required_fields=$(extract_required_fields "$approach")
        eval "$required_fields"
        echo "- **方式案${approach}**: $ASSIGNED_WORKER" >> "$output_file"
    done
    
    cat >> "$output_file" << EOF

### 優先度・工数サマリー
EOF
    
    # 優先度・工数サマリーを分析
    for approach in "${approaches[@]}"; do
        local required_fields
        required_fields=$(extract_required_fields "$approach")
        eval "$required_fields"
        echo "- **方式案${approach}**: 優先度=$PRIORITY, 工数=$ESTIMATED_HOURS, 難易度=$DIFFICULTY" >> "$output_file"
    done
}

# Worker適合度を判定（柔軟フォーマット対応）
calculate_worker_compatibility() {
    local approach_num="$1"
    local worker="$2"
    local tech_stack="$3"
    local difficulty="$4"
    
    local score=0
    local reasons=()
    
    # 技術スタック適合度
    case "$worker" in
        "worker1")
            if [[ "$tech_stack" =~ (React|Vue|Angular|TypeScript|JavaScript|CSS|HTML|UI|UX|Design|Frontend) ]]; then
                score=$((score + 40))
                reasons+=("フロントエンド技術との高い適合性")
            fi
            if [[ "$tech_stack" =~ (Tailwind|Bootstrap|Sass|Less) ]]; then
                score=$((score + 20))
                reasons+=("CSSフレームワークの専門性")
            fi
            ;;
        "worker2")
            if [[ "$tech_stack" =~ (Node\.js|Python|Java|Go|PHP|Backend|API|Database|SQL) ]]; then
                score=$((score + 40))
                reasons+=("バックエンド技術との高い適合性")
            fi
            if [[ "$tech_stack" =~ (PostgreSQL|MySQL|MongoDB|Redis|Docker|Kubernetes) ]]; then
                score=$((score + 20))
                reasons+=("インフラ・データベースの専門性")
            fi
            ;;
        "worker3")
            if [[ "$tech_stack" =~ (Test|Jest|Cypress|Playwright|E2E|Unit|Integration) ]]; then
                score=$((score + 40))
                reasons+=("テスト技術との高い適合性")
            fi
            if [[ "$tech_stack" =~ (CI/CD|GitHub Actions|Jenkins|Quality) ]]; then
                score=$((score + 20))
                reasons+=("品質保証・CI/CDの専門性")
            fi
            ;;
    esac
    
    # 難易度適合度
    case "$difficulty" in
        "初級"|"中級")
            score=$((score + 20))
            reasons+=("適切な難易度レベル")
            ;;
        "上級")
            score=$((score + 10))
            reasons+=("挑戦的な難易度")
            ;;
        "エキスパート")
            score=$((score + 5))
            reasons+=("高度な専門性が必要")
            ;;
    esac
    
    # 基本適合度（全Workerに適用）
    score=$((score + 20))
    reasons+=("基本的な開発能力")
    
    echo "$score"
    printf '%s\n' "${reasons[@]}"
}

# 方式案をWorkerに分配
assign_approaches() {
    log_header "👥 Worker分配処理開始"
    
    if ! validate_planlist; then
        return 1
    fi
    
    local approaches=($(grep "^## 方式案[0-9]" "$PLANLIST_FILE" | sed 's/^## 方式案\([0-9]\).*/\1/'))
    
    if [[ ${#approaches[@]} -eq 0 ]]; then
        log_error "分配する方式案が見つかりません"
        return 1
    fi
    
    log_info "分配対象方式案数: ${#approaches[@]}"
    
    for approach in "${approaches[@]}"; do
        log_info "方式案${approach}を分配中..."
        
        # 必須項目を抽出
        local required_fields
        required_fields=$(extract_required_fields "$approach")
        eval "$required_fields"
        
        # 方式案タイトルを抽出
        local title
        title=$(grep "^## 方式案${approach}:" "$PLANLIST_FILE" | sed "s/^## 方式案${approach}: *//" || echo "タイトル未設定")
        
        # 指定されたWorkerがある場合はそれを使用
        local target_worker="$ASSIGNED_WORKER"
        
        # Workerが指定されていない場合は自動判定
        if [[ -z "$target_worker" || "$target_worker" == "未指定" ]]; then
            log_info "Workerが未指定のため自動判定を実行..."
            
            local best_worker=""
            local best_score=0
            
            for worker in "worker1" "worker2" "worker3"; do
                local score_info
                score_info=$(calculate_worker_compatibility "$approach" "$worker" "$TECH_STACK" "$DIFFICULTY")
                local score=$(echo "$score_info" | head -n1)
                
                if [[ $score -gt $best_score ]]; then
                    best_score=$score
                    best_worker=$worker
                fi
                
                echo "  $worker: スコア $score"
            done
            
            target_worker="$best_worker"
            log_info "自動判定結果: $target_worker (スコア: $best_score)"
        else
            log_info "指定Worker: $target_worker"
        fi
        
        # 分配書を生成
        generate_assignment_document "$approach" "$target_worker" "$title" "$required_fields"
        
        log_success "方式案${approach}を${target_worker}に分配しました"
    done
    
    log_success "全方式案の分配が完了しました"
}

# 分配書を生成（柔軟フォーマット対応）
generate_assignment_document() {
    local approach_num="$1"
    local worker="$2"
    local title="$3"
    local required_fields="$4"
    
    eval "$required_fields"
    
    local assignment_file="$ASSIGNMENTS_DIR/${worker}_approach_${approach_num}.md"
    
    # 既存ファイルのバックアップ
    if [[ -f "$assignment_file" && "${FORCE_OVERWRITE:-false}" != "true" ]]; then
        local backup_file="${assignment_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$assignment_file" "$backup_file"
        log_info "既存の分配書をバックアップしました: $backup_file"
    fi
    
    cat > "$assignment_file" << EOF
# 📋 ${worker}への分配書 - 方式案${approach_num}

**生成日時**: $(date '+%Y-%m-%d %H:%M:%S')  
**分配元**: planlist.md  
**担当Worker**: $worker  
**方式案番号**: ${approach_num}

---

## 🎯 方式案概要

**タイトル**: $title  
**概要**: $OVERVIEW  
**優先度**: $PRIORITY  
**推定工数**: $ESTIMATED_HOURS  
**難易度**: $DIFFICULTY

---

## 🔧 技術スタック

$TECH_STACK

---

## 💡 詳細要件・仕様

EOF
    
    # フリーフォーマット詳細を追加
    extract_freeform_details "$approach_num" >> "$assignment_file"
    
    cat >> "$assignment_file" << EOF

---

## 👤 Worker情報

**担当Worker**: $worker  
**専門分野**: $(get_worker_specialty "$worker")  
**推奨アプローチ**: $(get_worker_approach "$worker")

---

## 📝 実装ガイドライン

### 基本方針
1. **品質重視**: コードの可読性と保守性を最優先
2. **段階的実装**: 小さな単位で実装・テスト・統合を繰り返し
3. **ドキュメント**: 実装と並行してドキュメントを更新
4. **コミュニケーション**: 不明点は積極的に質問・相談

### 実装フロー
1. **要件理解**: この分配書の内容を十分に理解
2. **技術調査**: 必要に応じて技術的な調査・検証
3. **設計**: アーキテクチャ・詳細設計の作成
4. **実装**: コード実装・テスト作成
5. **検証**: 動作確認・品質チェック
6. **報告**: 進捗・結果の報告

### 成果物
- [ ] 動作するコード/アプリケーション
- [ ] テストコード（適切なカバレッジ）
- [ ] ドキュメント（README、API仕様等）
- [ ] 実装報告書
- [ ] 今後の改善提案

---

## 📞 サポート・連絡先

**BOSS**: チーム全体の調整・意思決定  
**他Worker**: 技術的な相談・協力  
**PRESIDENT**: 最終判断・品質確認

### 報告タイミング
- **開始時**: 実装開始の報告
- **中間**: 進捗状況の報告（問題があれば随時）
- **完了時**: 成果物の提出・報告

---

## 📅 スケジュール目安

**推定工数**: $ESTIMATED_HOURS  
**難易度**: $DIFFICULTY  
**優先度**: $PRIORITY

### 推奨スケジュール
- **10%**: 要件理解・技術調査
- **20%**: 設計・計画
- **60%**: 実装・テスト
- **10%**: 検証・調整・報告

---

## ⚠️ 注意事項

1. **技術制約**: プロジェクトの技術スタックに準拠
2. **品質基準**: 既存コードとの一貫性を維持
3. **セキュリティ**: セキュリティベストプラクティスを遵守
4. **パフォーマンス**: 適切なパフォーマンスを確保

---

## 📊 進捗管理

### チェックリスト
- [ ] 分配書の内容を理解した
- [ ] 技術調査を完了した
- [ ] 設計を完了した
- [ ] 実装を開始した
- [ ] 実装を完了した
- [ ] テストを完了した
- [ ] ドキュメントを作成した
- [ ] 成果物を提出した

### 進捗報告フォーマット
\`\`\`
進捗: [0-100%]
現在の作業: [作業内容]
完了項目: [完了した項目]
次の予定: [次に取り組む項目]
課題・相談: [問題や相談事項]
\`\`\`

---

**📝 この分配書は${worker}の専門性を考慮して作成されました**  
**🎯 不明点があれば遠慮なく質問してください**  
**⭐ 品質の高い成果物の完成を期待しています**

EOF
    
    log_info "分配書を生成しました: $assignment_file"
}

# Worker専門分野を取得
get_worker_specialty() {
    case "$1" in
        "worker1") echo "UI/UXデザイン、フロントエンド開発" ;;
        "worker2") echo "バックエンド開発、データ処理、インフラ" ;;
        "worker3") echo "テスト・品質保証、CI/CD" ;;
        *) echo "未定義" ;;
    esac
}

# Worker推奨アプローチを取得
get_worker_approach() {
    case "$1" in
        "worker1") echo "ユーザー体験重視、デザインシステム活用" ;;
        "worker2") echo "スケーラビリティ重視、パフォーマンス最適化" ;;
        "worker3") echo "品質重視、自動化推進" ;;
        *) echo "未定義" ;;
    esac
}

# 分配レポートを生成
generate_distribution_report() {
    log_header "📊 分配レポート生成中..."
    
    local report_file="$REPORTS_DIR/distribution_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$report_file" << EOF
# 📊 Worker分配レポート

**生成日時**: $(date '+%Y-%m-%d %H:%M:%S')  
**分析対象**: $PLANLIST_FILE

---

## 📋 分配サマリー

EOF
    
    # 分配書ファイルを検索して情報を収集
    local total_assignments=0
    local worker1_count=0
    local worker2_count=0
    local worker3_count=0
    
    for assignment_file in "$ASSIGNMENTS_DIR"/*.md; do
        if [[ -f "$assignment_file" ]]; then
            total_assignments=$((total_assignments + 1))
            
            if [[ "$(basename "$assignment_file")" =~ ^worker1_ ]]; then
                worker1_count=$((worker1_count + 1))
            elif [[ "$(basename "$assignment_file")" =~ ^worker2_ ]]; then
                worker2_count=$((worker2_count + 1))
            elif [[ "$(basename "$assignment_file")" =~ ^worker3_ ]]; then
                worker3_count=$((worker3_count + 1))
            fi
        fi
    done
    
    cat >> "$report_file" << EOF
- **総分配数**: $total_assignments
- **Worker1**: $worker1_count件
- **Worker2**: $worker2_count件  
- **Worker3**: $worker3_count件

---

## 👥 Worker別分配詳細

EOF
    
    # 各Workerの分配詳細
    for worker in "worker1" "worker2" "worker3"; do
        cat >> "$report_file" << EOF
### $worker

**専門分野**: $(get_worker_specialty "$worker")  
**分配件数**: $(ls "$ASSIGNMENTS_DIR"/${worker}_*.md 2>/dev/null | wc -l)

#### 分配された方式案
EOF
        
        for assignment_file in "$ASSIGNMENTS_DIR"/${worker}_*.md; do
            if [[ -f "$assignment_file" ]]; then
                local approach_num
                approach_num=$(basename "$assignment_file" | sed 's/.*_approach_\([0-9]\)\.md/\1/')
                local title
                title=$(grep "^\*\*タイトル\*\*:" "$assignment_file" | sed 's/\*\*タイトル\*\*: *//' || echo "タイトル未設定")
                local priority
                priority=$(grep "^\*\*優先度\*\*:" "$assignment_file" | sed 's/\*\*優先度\*\*: *//' || echo "未設定")
                local estimated_hours
                estimated_hours=$(grep "^\*\*推定工数\*\*:" "$assignment_file" | sed 's/\*\*推定工数\*\*: *//' || echo "未設定")
                
                echo "- **方式案${approach_num}**: $title (優先度: $priority, 工数: $estimated_hours)" >> "$report_file"
            fi
        done
        
        echo "" >> "$report_file"
    done
    
    cat >> "$report_file" << EOF
---

## 📈 分析結果

### 分配バランス
EOF
    
    # 分配バランスの分析
    if [[ $total_assignments -gt 0 ]]; then
        local worker1_ratio=$((worker1_count * 100 / total_assignments))
        local worker2_ratio=$((worker2_count * 100 / total_assignments))
        local worker3_ratio=$((worker3_count * 100 / total_assignments))
        
        cat >> "$report_file" << EOF
- **Worker1**: ${worker1_ratio}% ($worker1_count/$total_assignments)
- **Worker2**: ${worker2_ratio}% ($worker2_count/$total_assignments)
- **Worker3**: ${worker3_ratio}% ($worker3_count/$total_assignments)

### 推奨事項
EOF
        
        # バランス分析と推奨事項
        if [[ $worker1_ratio -gt 50 ]]; then
            echo "- ⚠️ Worker1への集中が見られます。負荷分散を検討してください" >> "$report_file"
        fi
        if [[ $worker2_ratio -gt 50 ]]; then
            echo "- ⚠️ Worker2への集中が見られます。負荷分散を検討してください" >> "$report_file"
        fi
        if [[ $worker3_ratio -gt 50 ]]; then
            echo "- ⚠️ Worker3への集中が見られます。負荷分散を検討してください" >> "$report_file"
        fi
        
        if [[ $worker1_ratio -lt 20 && $worker2_ratio -lt 20 && $worker3_ratio -lt 20 ]]; then
            echo "- ✅ 良好な負荷分散が実現されています" >> "$report_file"
        fi
    fi
    
    cat >> "$report_file" << EOF

---

## 📁 生成ファイル

### 分配書
EOF
    
    # 生成された分配書のリスト
    for assignment_file in "$ASSIGNMENTS_DIR"/*.md; do
        if [[ -f "$assignment_file" ]]; then
            echo "- $(basename "$assignment_file")" >> "$report_file"
        fi
    done
    
    log_success "分配レポートを生成しました: $report_file"
}

# 現在の分配状況を表示
show_status() {
    log_header "📊 現在の分配状況"
    
    if [[ ! -d "$ASSIGNMENTS_DIR" ]]; then
        log_warning "分配書ディレクトリが存在しません"
        return 1
    fi
    
    local assignment_files=("$ASSIGNMENTS_DIR"/*.md)
    
    if [[ ! -f "${assignment_files[0]}" ]]; then
        log_warning "分配書が見つかりません"
        log_info "まず 'assign' コマンドを実行してください"
        return 1
    fi
    
    echo ""
    echo "📁 分配書ディレクトリ: $ASSIGNMENTS_DIR"
    echo "📄 分配書数: $(ls "$ASSIGNMENTS_DIR"/*.md 2>/dev/null | wc -l)"
    echo ""
    
    # Worker別の分配状況
    for worker in "worker1" "worker2" "worker3"; do
        local count
        count=$(ls "$ASSIGNMENTS_DIR"/${worker}_*.md 2>/dev/null | wc -l)
        echo "👤 $worker: $count件"
        
        for assignment_file in "$ASSIGNMENTS_DIR"/${worker}_*.md; do
            if [[ -f "$assignment_file" ]]; then
                local approach_num
                approach_num=$(basename "$assignment_file" | sed 's/.*_approach_\([0-9]\)\.md/\1/')
                local title
                title=$(grep "^\*\*タイトル\*\*:" "$assignment_file" | sed 's/\*\*タイトル\*\*: *//' || echo "タイトル未設定")
                echo "   └─ 方式案${approach_num}: $title"
            fi
        done
        echo ""
    done
    
    # 最新の分配日時
    local latest_file
    latest_file=$(ls -t "$ASSIGNMENTS_DIR"/*.md 2>/dev/null | head -n1)
    if [[ -f "$latest_file" ]]; then
        local latest_date
        latest_date=$(grep "^\*\*生成日時\*\*:" "$latest_file" | sed 's/\*\*生成日時\*\*: *//' || echo "不明")
        echo "📅 最新分配日時: $latest_date"
    fi
}

# メイン処理
main() {
    local command="${1:-help}"
    local force_flag=false
    local verbose_flag=false
    local dry_run_flag=false
    
    # オプション解析
    while [[ $# -gt 0 ]]; do
        case $1 in
            --planlist)
                PLANLIST_FILE="$2"
                shift 2
                ;;
            --force)
                FORCE_OVERWRITE="true"
                force_flag=true
                shift
                ;;
            --verbose)
                verbose_flag=true
                shift
                ;;
            --dry-run)
                dry_run_flag=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [[ -z "$command" || "$command" == "help" ]]; then
                    command="$1"
                fi
                shift
                ;;
        esac
    done
    
    # 詳細ログ設定
    if [[ "$verbose_flag" == "true" ]]; then
        set -x
    fi
    
    # ドライラン設定
    if [[ "$dry_run_flag" == "true" ]]; then
        log_info "ドライランモード: 実際の処理は行いません"
    fi
    
    # ディレクトリ初期化
    init_directories
    
    # コマンド実行
    case "$command" in
        analyze)
            analyze_planlist
            ;;
        assign)
            if [[ "$dry_run_flag" == "true" ]]; then
                log_info "[DRY-RUN] 分配処理をシミュレート中..."
                analyze_planlist
            else
                assign_approaches
            fi
            ;;
        report)
            generate_distribution_report
            ;;
        full)
            if [[ "$dry_run_flag" == "true" ]]; then
                log_info "[DRY-RUN] 全処理をシミュレート中..."
                analyze_planlist
            else
                analyze_planlist
                assign_approaches
                generate_distribution_report
            fi
            ;;
        status)
            show_status
            ;;
        help)
            show_help
            ;;
        *)
            log_error "不明なコマンド: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# スクリプト実行
main "$@" 