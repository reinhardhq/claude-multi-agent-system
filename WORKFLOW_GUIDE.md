# 🚀 並列開発ワークフローガイド

Git Worktree + Multi-Agent システムを使った効率的な並列開発フローの完全ガイド

## 📋 目次

1. [概要](#概要)
2. [システム構成](#システム構成)
3. [クイックスタート](#クイックスタート)
4. [詳細ワークフロー](#詳細ワークフロー)
5. [トラブルシューティング](#トラブルシューティング)
6. [ベストプラクティス](#ベストプラクティス)

## 概要

### 🎯 目的
- **独立性**: 各Workerが独立したワークスペースで作業
- **並列性**: 複数の方式案を同時に検討・実装
- **効率性**: ブランチ切り替えによる相互影響を完全排除
- **統合性**: 成果物の自動統合とレポート生成

### 🏗️ アーキテクチャ
```
👑 PRESIDENT (統括・意思決定)
    ↓
🎯 BOSS (チームリーダー・タスク管理)
    ↓
┌─────────────────────────────────────────┐
│ 🎨 WORKER1  │ ⚙️ WORKER2  │ 🧪 WORKER3  │
│ 汎用開発      │ 汎用開発    │ 汎用開発       │
│ 独立ブランチ  │ 独立ブランチ  │ 独立ブランチ  │
│ 独立作業空間  │ 独立作業空間  │ 独立作業空間  │
└─────────────────────────────────────────┘
```

## システム構成

### 📁 ディレクトリ構造
```
mastra-web-ui/
├── worktrees/                    # Git Worktree作業空間
│   ├── worker1/                  # Worker1専用ワークスペース
│   │   ├── .worker-config        # Worker設定
│   │   ├── ASSIGNMENT.md         # 配布された方式案
│   │   └── PROGRESS.md           # 進捗レポート
│   ├── worker2/                  # Worker2専用ワークスペース
│   └── worker3/                  # Worker3専用ワークスペース
│
├── claude_multi_agent_system/
│   ├── scripts/                  # 管理スクリプト群
│   │   ├── parallel-dev-manager.sh    # 統合管理
│   │   ├── worktree-manager.sh         # Worktree管理
│   │   ├── team-composer.sh            # チーム構成
│   │   ├── setup-multiagent.sh         # tmux環境構築
│   │   └── quick-start-multiagent.sh   # AI起動
│   ├── reports/                  # 自動生成レポート
│   ├── planlist.md              # 方式案定義
│   └── logs/                    # 開発ログ
```

### 🌿 ブランチ戦略
```
main
├── feature/approach-2-tool-scoped-dev-b  (現在のブランチ)
├── feature/worker-worker1-dev             (Worker1専用)
├── feature/worker-worker2-dev             (Worker2専用)
├── feature/worker-worker3-dev             (Worker3専用)
└── feature/integrated-results             (統合結果)
```

## クイックスタート

### 🚀 1分で開始

```bash
# 1. 並列開発環境の完全セットアップ
cd claude_multi_agent_system/scripts
./parallel-dev-manager.sh init

# 2. tmuxセッションに接続
./parallel-dev-manager.sh connect

# 3. 状況確認
./parallel-dev-manager.sh status
```

### 📋 セットアップ内容
`init` コマンドが自動実行する内容：

1. **Git Worktree環境構築** - 各Worker用の独立ワークスペース作成
2. **tmux環境構築** - 2ウィンドウ5ペイン構成
3. **planlist.md分析** - 方式案の自動分析
4. **方式案配布** - 各Workerへの自動配布
5. **AIエージェント起動** - 5つのAIエージェント起動

## 詳細ワークフロー

### Phase 1: 環境準備

#### 1.1 個別セットアップ（詳細制御したい場合）
```bash
# Worktree環境のみ構築
./worktree-manager.sh setup

# tmux環境のみ構築  
./setup-multiagent.sh

# AIエージェントのみ起動
./quick-start-multiagent.sh
```

#### 1.2 planlist.md の準備
```markdown
# planlist.md の形式例
## 方式案1: RESTful API + React Frontend
**概要**: 従来的なREST APIとReactフロントエンドの組み合わせ
**技術スタック**: Node.js, Express, React, PostgreSQL
...

## 方式案2: GraphQL + Next.js
**概要**: GraphQLとNext.jsを使用したモダンなフルスタック開発
**技術スタック**: Next.js, GraphQL, Prisma, TypeScript
...
```

### Phase 2: チーム構成・配布

#### 2.1 方式案分析
```bash
# planlist.mdの内容を分析
./team-composer.sh analyze
```

#### 2.2 方式案配布
```bash
# 全方式案を自動配布
./team-composer.sh assign

# 特定の方式案を配布
./team-composer.sh assign 1  # 方式案1をworker1に配布
```

#### 2.3 配布状況確認
```bash
# 各Workerの配布状況確認
./team-composer.sh status
```

### Phase 3: 並列開発

#### 3.1 tmuxセッション構成
```
ウィンドウ0: PRESIDENT (統括)
ウィンドウ1: 4分割
├── ペイン0: BOSS (チームリーダー)
├── ペイン1: WORKER1 (汎用開発)
├── ペイン2: WORKER2 (汎用開発)  
└── ペイン3: WORKER3 (汎用開発)
```

#### 3.2 各Workerの作業フロー

**Worker1 (汎用開発 Designer)**
```bash
# Worker1のワークスペースに移動
cd worktrees/worker1

# 配布書確認
cat ASSIGNMENT.md

# 実装開始
# ... 汎用開発実装 ...

# 進捗レポート作成
cat > PROGRESS.md << EOF
【進捗報告】$(date '+%Y-%m-%d')

【実装内容】
- レスポンシブデザイン実装
- React Component作成

【汎用開発での工夫】
- Material-UI導入
- アクセシビリティ対応

【課題・リスク】
- デザインシステム統一 → スタイルガイド作成

【次のステップ】
- ユーザビリティテスト
- デザインレビュー
EOF

# コミット・プッシュ
git add .
git commit -m "feat: implement responsive UI components"
git push origin feature/worker-worker1-dev
```

**Worker2 (汎用開発 Developer)**
```bash
# Worker2のワークスペースに移動
cd worktrees/worker2

# API実装
# ... 汎用開発実装 ...

# 進捗レポート作成
cat > PROGRESS.md << EOF
【進捗報告】$(date '+%Y-%m-%d')

【実装内容】
- REST API エンドポイント設計
- データベーススキーマ設計

【汎用開発での工夫】
- JWT認証実装
- レート制限機能追加

【課題・リスク】
- スケーラビリティ → Redis導入検討

【次のステップ】
- API文書化
- パフォーマンステスト
EOF

git add .
git commit -m "feat: implement REST API endpoints"
git push origin feature/worker-worker2-dev
```

**Worker3 (QA Engineer)**
```bash
# Worker3のワークスペースに移動
cd worktrees/worker3

# テスト実装
# ... 汎用開発実装 ...

# 進捗レポート作成
cat > PROGRESS.md << EOF
【進捗報告】$(date '+%Y-%m-%d')

【実装内容】
- E2Eテストスイート作成
- 単体テスト実装

【汎用開発での工夫】
- Playwright導入
- CI/CD統合

【課題・リスク】
- テストカバレッジ → 目標80%設定

【次のステップ】
- パフォーマンステスト
- セキュリティテスト
EOF

git add .
git commit -m "feat: implement comprehensive test suite"
git push origin feature/worker-worker3-dev
```

### Phase 4: 進捗管理・統合

#### 4.1 進捗収集
```bash
# 全Workerの進捗を自動収集
./team-composer.sh collect

# 生成されるレポート例
# reports/team_progress_20250124_143022.md
```

#### 4.2 ブランチ同期
```bash
# 全Workerブランチをリモートと同期
./parallel-dev-manager.sh sync
```

#### 4.3 成果物統合
```bash
# 各Workerの成果物を統合ブランチにマージ
./parallel-dev-manager.sh merge

# 統合結果確認
git log --oneline feature/integrated-results
```

#### 4.4 比較分析
```bash
# 方式案の比較分析レポート生成
./team-composer.sh compare

# 生成されるレポート例
# reports/approach_comparison_20250124_143022.md
```

### Phase 5: 品質保証・デプロイ

#### 5.1 統合後テスト
```bash
# 統合ブランチでのテスト実行
git checkout feature/integrated-results
npm test
npm run e2e
```

#### 5.2 品質チェック
```bash
# リンター・フォーマッター実行
npm run lint
npm run format

# セキュリティチェック
npm audit
```

## トラブルシューティング

### 🚨 よくある問題と解決法

#### 1. Worktreeが作成できない
```bash
# 原因: 既存のworktreeが残っている
# 解決: クリーンアップ後に再作成
./worktree-manager.sh cleanup
./worktree-manager.sh setup
```

#### 2. tmuxセッションに接続できない
```bash
# 原因: セッションが存在しない
# 解決: セッション再作成
./setup-multiagent.sh
./parallel-dev-manager.sh connect
```

#### 3. ブランチマージでコンフリクト
```bash
# 原因: 複数Workerが同じファイルを変更
# 解決: 手動でコンフリクト解決
git status
git add <resolved-files>
git commit -m "resolve merge conflicts"
```

#### 4. AIエージェントが起動しない
```bash
# 原因: Claude CLIの設定不備
# 解決: Claude CLI再設定
claude auth login
./quick-start-multiagent.sh
```

### 🔧 デバッグコマンド

```bash
# 全体状況確認
./parallel-dev-manager.sh status

# Worktree状況確認
./worktree-manager.sh list

# tmuxセッション確認
tmux list-sessions
tmux list-windows -t multiagent

# ログ確認
./parallel-dev-manager.sh logs
```

## ベストプラクティス

### 📝 開発フロー

1. **明確な役割分担**
   - Worker1: 汎用開発専門
   - Worker2: 汎用開発専門  
   - Worker3: 汎用開発専門

2. **定期的な進捗共有**
   - 1日1回の進捗レポート更新
   - 週1回の統合・レビュー

3. **コミット規約**
   ```
   feat: 新機能追加
   fix: バグ修正
   docs: ドキュメント更新
   test: テスト追加・修正
   refactor: リファクタリング
   ```

### 🎯 品質管理

1. **コードレビュー**
   - 統合前の必須レビュー
   - 専門分野での相互レビュー

2. **テスト戦略**
   - 単体テスト: 80%以上のカバレッジ
   - 統合テスト: API・DB連携テスト
   - E2Eテスト: 主要ユーザーフロー

3. **継続的インテグレーション**
   - プッシュ時の自動テスト実行
   - 品質ゲートの設定

### 🚀 効率化Tips

1. **並列作業の最大化**
   ```bash
   # 複数方式案の同時検討
   ./team-composer.sh assign 1  # Worker1に方式案1
   ./team-composer.sh assign 2  # Worker2に方式案2  
   ./team-composer.sh assign 3  # Worker3に方式案3
   ```

2. **自動化の活用**
   ```bash
   # 定期的な進捗収集（cron設定例）
   0 18 * * * cd /path/to/scripts && ./team-composer.sh collect
   ```

3. **レポート活用**
   - 進捗レポートでボトルネック特定
   - 比較分析レポートで最適解選択

### 🔒 セキュリティ

1. **ブランチ保護**
   - メインブランチへの直接プッシュ禁止
   - プルリクエスト必須

2. **アクセス制御**
   - Worker別の適切な権限設定
   - 機密情報の分離管理

---

## 📞 サポート

### 🆘 ヘルプコマンド
```bash
./parallel-dev-manager.sh help
./worktree-manager.sh help
./team-composer.sh help
```

### 📚 関連ドキュメント
- `README.md` - システム概要
- `QUICK_START.md` - クイックスタートガイド
- `president/president.md` - President役割定義
- `boss/boss.md` - Boss役割定義
- `worker/worker*.md` - Worker役割定義

---

*このガイドにより、効率的で品質の高い並列開発が実現できます！* 🚀 