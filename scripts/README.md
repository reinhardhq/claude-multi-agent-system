# Scripts Directory

このディレクトリには、Claude Multi-Agent Systemの各種管理スクリプトが含まれています。

## 🔧 コアスクリプト

### セットアップ・起動
- **setup-multiagent.sh** - tmuxセッションを作成し、マルチエージェント環境を準備
- **quick-start-multiagent.sh** - 各ペインでClaude AIエージェントを起動

### 設定管理
- **config-manager.sh** - プロジェクト設定の初期化・管理（推奨）
- **worktree-config.sh** - 設定ファイルベースのWorktree管理（推奨）
- **worktree-manager.sh** - 環境変数ベースのWorktree管理（レガシー）

## 📬 コミュニケーション

- **agent-send.sh** - 特定のエージェントまたはグループにメッセージを送信
- **boss-commander.sh** - Boss権限での統合操作パネル
  - タスク分析・分配（analyze, assign）
  - 進捗管理（check, review）
  - チーム指示（instruct, broadcast）

## 📋 タスク管理

- **assignment-manager.sh** - タイムスタンプベースのタスク分配管理
  - 日付/時刻別の整理
  - 自動クリーンアップ
  - アーカイブ機能

## 🔄 高度な開発管理

- **parallel-dev-manager.sh** - 並列開発の統合管理
- **team-composer.sh** - チーム構成の分析とレポート生成
- **master-controller.sh** - システム全体の統合制御

## 使用順序（推奨）

1. **初期設定**
   ```bash
   config-manager.sh init          # プロジェクト設定
   worktree-config.sh setup        # Worktree作成
   ```

2. **エージェント起動**
   ```bash
   setup-multiagent.sh             # tmuxセッション作成
   quick-start-multiagent.sh       # AIエージェント起動
   ```

3. **開発作業**
   ```bash
   boss-commander.sh assign        # タスク分配
   agent-send.sh worker1 "..."     # 個別指示
   progress-tracker.sh request     # 進捗確認
   ```

## スクリプトの依存関係

```
config-manager.sh
    └── worktree-config.sh
            └── assignment-manager.sh
                    └── boss-commander.sh
                            └── agent-send.sh

setup-multiagent.sh
    └── quick-start-multiagent.sh
            └── agent-send.sh
```

## 注意事項

- 全てのスクリプトは実行権限が必要です（`chmod +x`）
- tmuxがインストールされている必要があります
- Claude CLIが認証済みである必要があります
- プロジェクト設定は事前に `config-manager.sh init` で初期化してください