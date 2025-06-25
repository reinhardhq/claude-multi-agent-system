#!/bin/bash
# ==============================================================================
# Setup Multi-Agent - Claudeマルチエージェントシステムセットアップ
# ==============================================================================
# Description: President/Boss/Worker 3層構造のマルチエージェントシステムを設定
# Usage: setup-multiagent.sh
# Dependencies: tmux, curl
# ==============================================================================

set -e

echo "🚀 Claude Multi-Agent System セットアップ開始"
echo "📋 構成: President → Boss → Worker1(UI/UX) + Worker2(Backend) + Worker3(Test)"

# セッション名
SESSION_NAME="multiagent"

# 既存セッションがあれば削除
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "⚠️  既存セッション '$SESSION_NAME' を削除します"
    tmux kill-session -t $SESSION_NAME
fi

echo "🏗️  新しいセッションを作成中..."

# 新しいセッションを作成（最初のウィンドウ: President）
tmux new-session -d -s $SESSION_NAME -n "president"

# ウィンドウ0（President）の設定
tmux send-keys -t $SESSION_NAME:0 "echo '👑 PRESIDENT - 最高経営者'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '役割: プロジェクト全体の統括責任者'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo 'ドキュメント: president/president.md を参照'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo ''" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '💡 使用方法:'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '1. あなたはpresidentです。[プロジェクト要求] と入力'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '2. BOSSが自動的にタスク分解・配分'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '3. WORKERsが並列で実装'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo '4. 統合・完成'" C-m
tmux send-keys -t $SESSION_NAME:0 "echo ''" C-m

# ウィンドウ1（Boss + 3Workers）の作成と4分割
tmux new-window -t $SESSION_NAME:1 -n "team"

# 最初のペイン（Boss）
tmux send-keys -t $SESSION_NAME:1.0 "echo '🎯 BOSS - チームリーダー'" C-m
tmux send-keys -t $SESSION_NAME:1.0 "echo '役割: タスク分解・配分・進捗管理'" C-m
tmux send-keys -t $SESSION_NAME:1.0 "echo 'ドキュメント: boss/boss.md を参照'" C-m

# 右に分割してWorker1
tmux split-window -t $SESSION_NAME:1.0 -h
tmux send-keys -t $SESSION_NAME:1.1 "echo '🎨 WORKER1 - UI/UXデザイン担当'" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo '役割: ユーザーインターフェース設計・実装'" C-m
tmux send-keys -t $SESSION_NAME:1.1 "echo 'ドキュメント: worker/worker1-ui-ux.md を参照'" C-m

# 下に分割してWorker2
tmux split-window -t $SESSION_NAME:1.0 -v
tmux send-keys -t $SESSION_NAME:1.2 "echo '⚙️  WORKER2 - バックエンド・データ処理'" C-m
tmux send-keys -t $SESSION_NAME:1.2 "echo '役割: API設計・DB設計・システム構築'" C-m
tmux send-keys -t $SESSION_NAME:1.2 "echo 'ドキュメント: worker/worker2-backend.md を参照'" C-m

# 右下にWorker3
tmux split-window -t $SESSION_NAME:1.1 -v
tmux send-keys -t $SESSION_NAME:1.3 "echo '🧪 WORKER3 - テスト・品質保証'" C-m
tmux send-keys -t $SESSION_NAME:1.3 "echo '役割: テスト戦略・品質管理・自動化'" C-m
tmux send-keys -t $SESSION_NAME:1.3 "echo 'ドキュメント: worker/worker3-test.md を参照'" C-m

# レイアウトを調整（均等分割）
tmux select-layout -t $SESSION_NAME:1 tiled

echo "✅ セッションセットアップ完了"
echo ""
echo "📱 接続方法:"
echo "   tmux attach-session -t $SESSION_NAME"
echo ""
echo "🏢 画面構成:"
echo "   ウィンドウ0: 👑 PRESIDENT（統括）"
echo "   ウィンドウ1: 🎯 BOSS + 🎨 WORKER1 + ⚙️ WORKER2 + 🧪 WORKER3"
echo ""
echo "🎮 操作方法:"
echo "   Ctrl+B → 0    : PRESIDENTウィンドウに切り替え"
echo "   Ctrl+B → 1    : チームウィンドウに切り替え"
echo "   Ctrl+B → 矢印 : ペイン間移動"
echo ""
echo "🚀 次のステップ:"
echo "   ./quick-start-multiagent.sh でClaude AIエージェントを起動"
echo ""

# Presidentウィンドウをアクティブにして終了
tmux select-window -t $SESSION_NAME:0 