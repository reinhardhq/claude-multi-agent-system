#!/bin/bash
# ==============================================================================
# Configuration Manager - Claudeマルチエージェントシステム設定管理
# ==============================================================================
# Description: プロジェクト設定ファイルと環境セットアップを管理
# Usage: config-manager.sh [create|update|load|show]
# Dependencies: git, jq
# ==============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SYSTEM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Default paths
DEFAULT_CONFIG_DIR="$CLAUDE_SYSTEM_ROOT/config"
DEFAULT_CONFIG_FILE="project.config"
CONFIG_EXAMPLE="$DEFAULT_CONFIG_DIR/project.config.example"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Show usage
show_usage() {
    echo -e "${CYAN}🔧 Configuration Manager${NC}"
    echo ""
    echo "Manages project configuration for Claude Multi-Agent System"
    echo ""
    echo "Usage:"
    echo "  $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}init${NC}             - Initialize configuration for current project"
    echo -e "  ${GREEN}load${NC} [file]      - Load configuration from file"
    echo -e "  ${GREEN}show${NC}             - Display current configuration"
    echo -e "  ${GREEN}validate${NC}         - Validate configuration"
    echo -e "  ${GREEN}export${NC}           - Export configuration as environment variables"
    echo -e "  ${GREEN}edit${NC}             - Edit configuration file"
    echo ""
    echo "Options:"
    echo "  -f, --file <path>   Configuration file path"
    echo "  -p, --project <path> Project root directory"
    echo ""
    echo "Examples:"
    echo "  $0 init                    # Interactive setup"
    echo "  $0 init -p /path/to/project"
    echo "  $0 load myproject.config"
    echo "  $0 show"
    echo ""
}

# Find configuration file
find_config_file() {
    local search_paths=(
        "./project.config"
        "./.claude-multi-agent/project.config"
        "./config/project.config"
        "$DEFAULT_CONFIG_DIR/project.config"
        "$HOME/.claude-multi-agent/project.config"
    )
    
    for path in "${search_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Load configuration
load_config() {
    local config_file="$1"
    
    if [ -z "$config_file" ]; then
        config_file=$(find_config_file) || {
            echo -e "${RED}❌ 設定ファイルが見つかりません${NC}"
            echo -e "${YELLOW}💡 'config-manager.sh init' で設定を初期化してください${NC}"
            return 1
        }
    fi
    
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}❌ 設定ファイルが存在しません: $config_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📄 設定を読み込み中: $config_file${NC}"
    source "$config_file"
    
    # Export all variables
    export PROJECT_NAME PROJECT_ROOT PROJECT_REPOSITORY
    export CLAUDE_SYSTEM_PATH WORKTREE_BASE BRANCH_PATTERN
    export WORKER_COUNT WORKER_NAMES
    export DEFAULT_MODEL PRESIDENT_MODEL BOSS_MODEL WORKER_MODEL
    export AUTO_COMMIT COMMIT_INTERVAL PROGRESS_REPORT_INTERVAL
    export SESSION_NAME LOG_LEVEL LOG_DIR
    
    echo -e "${GREEN}✅ 設定を読み込みました${NC}"
}

# Initialize configuration
init_config() {
    local project_root="${1:-$(pwd)}"
    local config_dir="$project_root/.claude-multi-agent"
    local config_file="$config_dir/project.config"
    
    echo -e "${CYAN}🚀 Claude Multi-Agent System 設定初期化${NC}"
    echo ""
    
    # Create config directory
    mkdir -p "$config_dir"
    
    # Check if config already exists
    if [ -f "$config_file" ]; then
        echo -e "${YELLOW}⚠️  既存の設定ファイルが見つかりました: $config_file${NC}"
        echo -n "上書きしますか？ (y/N): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            echo "キャンセルしました"
            return 1
        fi
    fi
    
    # Interactive setup
    echo -e "${WHITE}プロジェクト情報を入力してください:${NC}"
    
    # Project name
    local default_name=$(basename "$project_root")
    echo -n "プロジェクト名 [$default_name]: "
    read -r project_name
    project_name=${project_name:-$default_name}
    
    # Project repository
    local default_repo=""
    if cd "$project_root" && git remote get-url origin >/dev/null 2>&1; then
        default_repo=$(git remote get-url origin)
    fi
    echo -n "リポジトリURL [$default_repo]: "
    read -r project_repo
    project_repo=${project_repo:-$default_repo}
    
    # Claude system path
    echo -n "Claude Multi-Agent System パス [$CLAUDE_SYSTEM_ROOT]: "
    read -r claude_path
    claude_path=${claude_path:-$CLAUDE_SYSTEM_ROOT}
    
    # Worker count
    echo -n "Worker数 [3]: "
    read -r worker_count
    worker_count=${worker_count:-3}
    
    # Model selection
    echo -n "使用するClaudeモデル [claude-4-sonnet]: "
    read -r model
    model=${model:-claude-4-sonnet}
    
    # Create configuration file
    cat > "$config_file" << EOF
# Claude Multi-Agent System Project Configuration
# Generated on $(date)

# ===== Project Information =====
PROJECT_NAME="$project_name"
PROJECT_ROOT="$project_root"
PROJECT_REPOSITORY="$project_repo"

# ===== Multi-Agent System Paths =====
CLAUDE_SYSTEM_PATH="$claude_path"

# ===== Worktree Configuration =====
WORKTREE_BASE="worktrees"
BRANCH_PATTERN="feature/{worker}-dev"

# ===== Worker Configuration =====
WORKER_COUNT=$worker_count
WORKER_NAMES="$(seq -s' ' -f 'worker%.0f' 1 $worker_count)"

# ===== Agent Model Configuration =====
DEFAULT_MODEL="$model"
PRESIDENT_MODEL="$model"
BOSS_MODEL="$model"
WORKER_MODEL="$model"

# ===== Development Settings =====
AUTO_COMMIT=false
COMMIT_INTERVAL="30m"
PROGRESS_REPORT_INTERVAL="10m"

# ===== Integration Settings =====
GITHUB_CREATE_PR=false
GITHUB_PR_TEMPLATE=".github/pull_request_template.md"

# ===== Advanced Settings =====
SESSION_NAME="multiagent"
LOG_LEVEL="INFO"
LOG_DIR="\${CLAUDE_SYSTEM_PATH}/logs"
EOF

    echo ""
    echo -e "${GREEN}✅ 設定ファイルを作成しました: $config_file${NC}"
    echo ""
    echo -e "${CYAN}次のステップ:${NC}"
    echo "1. 設定を確認: $0 show"
    echo "2. Worktreeをセットアップ: worktree-config.sh setup"
    echo "3. エージェントを起動: setup-multiagent.sh"
}

# Show configuration
show_config() {
    local config_file=$(find_config_file) || {
        echo -e "${RED}❌ 設定ファイルが見つかりません${NC}"
        return 1
    }
    
    echo -e "${CYAN}📋 現在の設定${NC}"
    echo -e "${WHITE}設定ファイル: $config_file${NC}"
    echo ""
    
    # Load and display
    source "$config_file"
    
    echo -e "${YELLOW}[プロジェクト情報]${NC}"
    echo "  PROJECT_NAME: $PROJECT_NAME"
    echo "  PROJECT_ROOT: $PROJECT_ROOT"
    echo "  PROJECT_REPOSITORY: $PROJECT_REPOSITORY"
    echo ""
    
    echo -e "${YELLOW}[システムパス]${NC}"
    echo "  CLAUDE_SYSTEM_PATH: $CLAUDE_SYSTEM_PATH"
    echo "  WORKTREE_BASE: $WORKTREE_BASE"
    echo ""
    
    echo -e "${YELLOW}[Worker設定]${NC}"
    echo "  WORKER_COUNT: $WORKER_COUNT"
    echo "  WORKER_NAMES: $WORKER_NAMES"
    echo "  BRANCH_PATTERN: $BRANCH_PATTERN"
    echo ""
    
    echo -e "${YELLOW}[モデル設定]${NC}"
    echo "  DEFAULT_MODEL: $DEFAULT_MODEL"
    echo "  PRESIDENT_MODEL: $PRESIDENT_MODEL"
    echo "  BOSS_MODEL: $BOSS_MODEL"
    echo "  WORKER_MODEL: $WORKER_MODEL"
}

# Validate configuration
validate_config() {
    local config_file=$(find_config_file) || {
        echo -e "${RED}❌ 設定ファイルが見つかりません${NC}"
        return 1
    }
    
    echo -e "${CYAN}🔍 設定を検証中...${NC}"
    
    source "$config_file"
    
    local errors=0
    
    # Check required fields
    if [ -z "$PROJECT_ROOT" ]; then
        echo -e "${RED}❌ PROJECT_ROOT が設定されていません${NC}"
        ((errors++))
    elif [ ! -d "$PROJECT_ROOT" ]; then
        echo -e "${RED}❌ PROJECT_ROOT が存在しません: $PROJECT_ROOT${NC}"
        ((errors++))
    fi
    
    if [ -z "$CLAUDE_SYSTEM_PATH" ]; then
        echo -e "${RED}❌ CLAUDE_SYSTEM_PATH が設定されていません${NC}"
        ((errors++))
    elif [ ! -d "$CLAUDE_SYSTEM_PATH" ]; then
        echo -e "${RED}❌ CLAUDE_SYSTEM_PATH が存在しません: $CLAUDE_SYSTEM_PATH${NC}"
        ((errors++))
    fi
    
    # Check git repository
    if [ -d "$PROJECT_ROOT" ]; then
        if ! (cd "$PROJECT_ROOT" && git rev-parse --git-dir >/dev/null 2>&1); then
            echo -e "${YELLOW}⚠️  PROJECT_ROOT はGitリポジトリではありません${NC}"
        fi
    fi
    
    # Check Claude CLI
    if ! command -v claude >/dev/null 2>&1; then
        echo -e "${YELLOW}⚠️  Claude CLIがインストールされていません${NC}"
    fi
    
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✅ 設定は有効です${NC}"
        return 0
    else
        echo -e "${RED}❌ $errors 個のエラーが見つかりました${NC}"
        return 1
    fi
}

# Export configuration
export_config() {
    local config_file=$(find_config_file) || {
        echo -e "${RED}❌ 設定ファイルが見つかりません${NC}"
        return 1
    }
    
    echo -e "${CYAN}📤 環境変数をエクスポート...${NC}"
    
    # Generate export commands
    echo "# Claude Multi-Agent System Environment Variables"
    echo "# Source this file: source <(config-manager.sh export)"
    echo ""
    
    source "$config_file"
    
    # Export all variables
    for var in PROJECT_NAME PROJECT_ROOT PROJECT_REPOSITORY \
               CLAUDE_SYSTEM_PATH WORKTREE_BASE BRANCH_PATTERN \
               WORKER_COUNT WORKER_NAMES \
               DEFAULT_MODEL PRESIDENT_MODEL BOSS_MODEL WORKER_MODEL \
               AUTO_COMMIT COMMIT_INTERVAL PROGRESS_REPORT_INTERVAL \
               SESSION_NAME LOG_LEVEL LOG_DIR; do
        if [ -n "${!var}" ]; then
            echo "export $var=\"${!var}\""
        fi
    done
    
    # Add PATH
    echo "export PATH=\"\$PATH:$CLAUDE_SYSTEM_PATH/scripts\""
}

# Edit configuration
edit_config() {
    local config_file=$(find_config_file) || {
        echo -e "${RED}❌ 設定ファイルが見つかりません${NC}"
        echo -e "${YELLOW}💡 'config-manager.sh init' で設定を初期化してください${NC}"
        return 1
    }
    
    local editor="${EDITOR:-vim}"
    echo -e "${CYAN}📝 設定ファイルを編集: $config_file${NC}"
    $editor "$config_file"
}

# Main logic
case "$1" in
    init)
        shift
        init_config "$@"
        ;;
    load)
        shift
        load_config "$@"
        ;;
    show)
        show_config
        ;;
    validate)
        validate_config
        ;;
    export)
        export_config
        ;;
    edit)
        edit_config
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        if [ -n "$1" ]; then
            echo -e "${RED}❌ 不明なコマンド: $1${NC}"
            echo ""
        fi
        show_usage
        exit 1
        ;;
esac