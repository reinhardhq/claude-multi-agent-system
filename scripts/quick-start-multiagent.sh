#!/bin/bash
# ==============================================================================
# Quick Start Multi-Agent - Claudeマルチエージェントシステムクイックスタート
# ==============================================================================
# Description: President/Boss/Worker 3層構造のマルチエージェントシステムを素早く起動
# Usage: quick-start-multiagent.sh
# Dependencies: tmux, curl
# ==============================================================================

set -e

SESSION_NAME="multiagent"

echo "🚀 Claude Multi-Agent System 起動中..."

# セッションの存在確認
if ! tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "❌ セッション '$SESSION_NAME' が見つかりません"
    echo "💡 先に ./setup-multiagent.sh を実行してください"
    exit 1
fi

echo "🎯 各エージェントにClaude AIを起動中..."

# PRESIDENT（ウィンドウ0）
echo "👑 PRESIDENT を起動中..."
tmux send-keys -t $SESSION_NAME:0 "clear" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '👑 PRESIDENT - Claude AI 起動中...'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'あなたはPRESIDENTです。'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'ドキュメント: president/president.md を参照してください。'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0 "claude --dangerously-skip-permissions" C-m

sleep 2

# BOSS（ウィンドウ1、ペイン0）
echo "🎯 BOSS を起動中..."
tmux send-keys -t $SESSION_NAME:1.0 "clear" C-m
tmux send-keys -t $SESSION_NAME:1.0 "echo '🎯 BOSS - Claude AI 起動中...'" C-m
tmux send-keys -t $SESSION_NAME:1.0 "echo 'あなたはBOSSです。'" C-m
tmux send-keys -t $SESSION_NAME:1.0 "echo 'ドキュメント: boss/boss.md を参照してください。'" C-m
tmux send-keys -t $SESSION_NAME:1.0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:1.0 "claude --dangerously-skip-permissions" C-m

sleep 2

# WORKER1 - UI/UX（ウィンドウ1、ペイン1）
echo "🎨 WORKER1 (UI/UX) を起動中..."
tmux send-keys -t $SESSION_NAME:1.1 "clear" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo '🎨 WORKER1 - UI/UXデザイン担当 Claude AI 起動中...'" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo 'あなたはWORKER1です。'" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo 'ドキュメント: worker/worker1-ui-ux.md を参照してください。'" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:1.1 "claude --dangerously-skip-permissions" C-m

sleep 2

# WORKER2 - Backend（ウィンドウ1、ペイン2）
echo "⚙️  WORKER2 (Backend) を起動中..."
tmux send-keys -t $SESSION_NAME:1.2 "clear" C-m
tmux send-keys -t $SESSION_NAME:1.2 "echo '⚙️  WORKER2 - バックエンド・データ処理担当 Claude AI 起動中...'" C-m
tmux send-keys -t $SESSION_NAME:1.2 "echo 'あなたはWORKER2です。'" C-m
tmux send-keys -t $SESSION_NAME:1.2 "echo 'ドキュメント: worker/worker2-backend.md を参照してください。'" C-m
tmux send-keys -t $SESSION_NAME:1.2 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:1.2 "claude --dangerously-skip-permissions" C-m

sleep 2

# WORKER3 - Test（ウィンドウ1、ペイン3）
echo "🧪 WORKER3 (Test) を起動中..."
tmux send-keys -t $SESSION_NAME:1.3 "clear" C-m
tmux send-keys -t $SESSION_NAME:1.3 "echo '🧪 WORKER3 - テスト・品質保証担当 Claude AI 起動中...'" C-m
tmux send-keys -t $SESSION_NAME:1.3 "echo 'あなたはWORKER3です。'" C-m
tmux send-keys -t $SESSION_NAME:1.3 "echo 'ドキュメント: worker/worker3-test.md を参照してください。'" C-m
tmux send-keys -t $SESSION_NAME:1.3 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:1.3 "claude --dangerously-skip-permissions" C-m

echo ""
echo "✅ 全エージェント起動完了！"
echo ""
echo "📱 接続方法:"
echo "   tmux attach-session -t $SESSION_NAME"
echo ""
echo "🏢 画面構成:"
echo "   ウィンドウ0: 👑 PRESIDENT（統括・意思決定）"
echo "   ウィンドウ1: 🎯 BOSS（管理） + 🎨 WORKER1（UI/UX） + ⚙️ WORKER2（Backend） + 🧪 WORKER3（Test）"
echo ""
echo "🎮 操作方法:"
echo "   Ctrl+B → 0    : PRESIDENTウィンドウに切り替え"
echo "   Ctrl+B → 1    : チームウィンドウに切り替え"
echo "   Ctrl+B → 矢印 : ペイン間移動"
echo ""
echo "💡 使用例:"
echo "   1. PRESIDENTで: 'あなたはpresidentです。TODOアプリを作成してください。'"
echo "   2. BOSSが自動的にタスクを分解・配分"
echo "   3. WORKER1-3が並列で実装"
echo "   4. 統合・完成"
echo ""
echo "🎯 各エージェントの認証が必要な場合があります。ブラウザでClaude認証を完了してください。" 