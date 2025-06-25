#!/bin/bash

# Plan Distributor - 方式案配布システム
# planlist.mdの方式案を各開発チームに自動配布するシステム

set -e

# 設定
SESSION_NAME="multiagent"
PLANLIST_FILE="../planlist.md"
LOGS_DIR="../logs"
DISTRIBUTION_LOG="$LOGS_DIR/plan_distribution.log"

# ディレクトリ作成
mkdir -p "$LOGS_DIR"

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
    echo -e "${PURPLE}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║                    PLAN DISTRIBUTOR                           ║"
    echo "║                   方式案配布システム                           ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# planlist.mdサンプル作成
create_sample_planlist() {
    if [[ ! -f "$PLANLIST_FILE" ]]; then
        echo -e "${YELLOW}planlist.mdが見つかりません。サンプルを作成します...${NC}"
        
        cat > "$PLANLIST_FILE" << 'EOF'
# 開発方式案リスト

## 方式案1: RESTful API + React Frontend
**概要**: 従来的なREST APIとReactフロントエンドの組み合わせ
**技術スタック**: Node.js, Express, React, PostgreSQL
**特徴**:
- 実績のある技術スタック
- 開発者の習熟度が高い
- 豊富なライブラリとツール

**実装要件**:
1. REST APIエンドポイント設計
2. データベーススキーマ設計
3. フロントエンドコンポーネント設計
4. 認証・認可システム
5. テスト戦略

**期待される成果物**:
- API仕様書
- データベース設計書
- フロントエンド設計書
- プロトタイプ実装

---

## 方式案2: GraphQL + Next.js
**概要**: GraphQLとNext.jsを使用したモダンなフルスタック開発
**技術スタック**: Next.js, GraphQL, Prisma, TypeScript
**特徴**:
- 型安全性の確保
- 効率的なデータフェッチング
- SSR/SSGによる高速化

**実装要件**:
1. GraphQLスキーマ設計
2. Resolverの実装
3. Next.jsページ構成
4. 状態管理設計
5. パフォーマンス最適化

**期待される成果物**:
- GraphQLスキーマ
- アーキテクチャ設計書
- パフォーマンス分析
- 実装サンプル

---

## 方式案3: Microservices + Docker
**概要**: マイクロサービスアーキテクチャとコンテナ化
**技術スタック**: Docker, Kubernetes, Node.js, MongoDB
**特徴**:
- スケーラビリティ
- 独立したデプロイ
- 技術スタックの多様性

**実装要件**:
1. サービス分割設計
2. API Gateway設計
3. データベース分散設計
4. 監視・ログ設計
5. CI/CD パイプライン

**期待される成果物**:
- マイクロサービス設計書
- インフラ構成図
- 運用手順書
- 実装計画書
EOF
        
        echo -e "${GREEN}サンプルplanlist.mdを作成しました: $PLANLIST_FILE${NC}"
    fi
}

# 方式案解析
parse_planlist() {
    if [[ ! -f "$PLANLIST_FILE" ]]; then
        echo -e "${RED}エラー: $PLANLIST_FILE が見つかりません${NC}"
        return 1
    fi
    
    # 方式案の数を取得
    local plan_count=$(grep -c "^## 方式案[0-9]" "$PLANLIST_FILE" 2>/dev/null || echo "0")
    echo "$plan_count"
}

# 特定の方式案を抽出
extract_plan() {
    local plan_number="$1"
    
    if [[ ! -f "$PLANLIST_FILE" ]]; then
        echo -e "${RED}エラー: $PLANLIST_FILE が見つかりません${NC}"
        return 1
    fi
    
    # 方式案を抽出
    awk "/^## 方式案${plan_number}:/,/^## 方式案[0-9]+:|^---$|^$/" "$PLANLIST_FILE" | head -n -1
}

# 方式案一覧表示
list_plans() {
    echo -e "${YELLOW}=== 利用可能な方式案 ===${NC}"
    
    if [[ ! -f "$PLANLIST_FILE" ]]; then
        echo -e "${RED}planlist.mdが見つかりません${NC}"
        return 1
    fi
    
    local plan_count=$(parse_planlist)
    
    if [[ "$plan_count" -eq 0 ]]; then
        echo -e "${RED}方式案が見つかりません${NC}"
        return 1
    fi
    
    for i in $(seq 1 "$plan_count"); do
        local title=$(grep "^## 方式案${i}:" "$PLANLIST_FILE" | sed "s/^## 方式案${i}: //")
        local overview=$(grep -A 1 "^**概要**:" "$PLANLIST_FILE" | tail -1)
        
        echo -e "${WHITE}方式案${i}:${NC} ${CYAN}$title${NC}"
        echo -e "  概要: $overview"
        echo ""
    done
}

# 個別配布
distribute_plan() {
    local plan_number="$1"
    local target_team="$2"
    
    if [[ -z "$plan_number" || -z "$target_team" ]]; then
        echo -e "${RED}使用方法: distribute_plan <方式案番号> <チーム番号>${NC}"
        return 1
    fi
    
    # tmuxセッション確認
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo -e "${RED}エラー: tmuxセッション '$SESSION_NAME' が見つかりません${NC}"
        return 1
    fi
    
    # 方式案抽出
    local plan_content=$(extract_plan "$plan_number")
    
    if [[ -z "$plan_content" ]]; then
        echo -e "${RED}エラー: 方式案${plan_number}が見つかりません${NC}"
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
    
    echo -e "${GREEN}[$timestamp] 方式案${plan_number}を${team_name}に配布中...${NC}"
    
    # 配布メッセージ作成
    local distribution_message="【方式案配布】プレジデントより方式案${plan_number}を配布いたします。

$plan_content

【指示事項】
1. 上記方式案を詳細に検討してください
2. 技術的実現性を評価してください
3. 実装計画を策定してください
4. 課題・リスクを特定してください
5. 24時間以内に初期検討結果を報告してください

【報告形式】
- 技術的評価（5段階）
- 実装工数見積もり
- 主要な課題
- 推奨度とその理由

よろしくお願いいたします。"
    
    # tmuxペインに送信
    tmux send-keys -t "$SESSION_NAME:0.$target_team" "$distribution_message" Enter
    
    # ログ記録
    echo "[$timestamp] PLAN_DISTRIBUTION: Plan$plan_number -> $team_name" >> "$DISTRIBUTION_LOG"
    
    echo -e "${CYAN}方式案${plan_number}を${team_name}に配布完了${NC}"
}

# 全方式案自動配布
distribute_all_plans() {
    echo -e "${YELLOW}=== 全方式案自動配布 ===${NC}"
    
    local plan_count=$(parse_planlist)
    
    if [[ "$plan_count" -eq 0 ]]; then
        echo -e "${RED}配布可能な方式案がありません${NC}"
        return 1
    fi
    
    if [[ "$plan_count" -gt 3 ]]; then
        echo -e "${YELLOW}警告: 方式案が3つを超えています（${plan_count}個）${NC}"
        echo -e "${YELLOW}最初の3つの方式案のみ配布します${NC}"
        plan_count=3
    fi
    
    for i in $(seq 1 "$plan_count"); do
        echo -e "${GREEN}方式案${i}をDEV-${i}に配布中...${NC}"
        
        case $i in
            1) distribute_plan "$i" "1" ;;
            2) distribute_plan "$i" "2" ;;
            3) distribute_plan "$i" "3" ;;
        esac
        
        sleep 2  # 配布間隔
    done
    
    echo -e "${CYAN}全方式案の配布が完了しました${NC}"
}

# 配布履歴表示
show_distribution_history() {
    echo -e "${YELLOW}=== 配布履歴 ===${NC}"
    
    if [[ -f "$DISTRIBUTION_LOG" ]]; then
        tail -20 "$DISTRIBUTION_LOG"
    else
        echo "配布履歴がありません"
    fi
}

# 使用方法表示
show_usage() {
    echo -e "${CYAN}Plan Distributor 使用方法:${NC}"
    echo ""
    echo -e "${WHITE}基本コマンド:${NC}"
    echo "  ./plan-distributor.sh list                    # 方式案一覧表示"
    echo "  ./plan-distributor.sh distribute <方式案> <チーム>  # 個別配布"
    echo "  ./plan-distributor.sh auto                    # 全方式案自動配布"
    echo "  ./plan-distributor.sh history                 # 配布履歴表示"
    echo "  ./plan-distributor.sh sample                  # サンプルplanlist.md作成"
    echo ""
    echo -e "${WHITE}例:${NC}"
    echo "  ./plan-distributor.sh distribute 1 1         # 方式案1をDEV-Aに配布"
    echo "  ./plan-distributor.sh distribute 2 dev-b     # 方式案2をDEV-Bに配布"
    echo "  ./plan-distributor.sh auto                    # 全自動配布"
}

# メイン処理
main() {
    show_logo
    
    case "${1:-help}" in
        list|ls)
            create_sample_planlist
            list_plans
            ;;
        distribute|dist)
            create_sample_planlist
            distribute_plan "$2" "$3"
            ;;
        auto|all)
            create_sample_planlist
            distribute_all_plans
            ;;
        history|hist)
            show_distribution_history
            ;;
        sample)
            create_sample_planlist
            echo -e "${GREEN}サンプルplanlist.mdを作成しました${NC}"
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