#!/bin/bash
# ==============================================================================
# Claude Multi-Agent Init - 簡単な初期化スクリプト
# ==============================================================================
# Description: 外部プロジェクトでClaude Multi-Agent Systemを簡単に初期化
# Usage: claude-multi-agent-init.sh [project-path] [options]
# Dependencies: git, tmux, jq
# ==============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYSTEM_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Default values
DEFAULT_WORKERS="worker1 worker2 worker3"
DEFAULT_MODEL="claude-4o-latest"
DEFAULT_BRANCH_PATTERN="feature/worker-{worker}-dev"

# Show usage
show_usage() {
    echo -e "${CYAN}🚀 Claude Multi-Agent System - Quick Initializer${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 [project-path] [options]"
    echo ""
    echo "Options:"
    echo "  --workers NUM      Number of workers (default: 3)"
    echo "  --model MODEL      Claude model to use (default: claude-4o-latest)"
    echo "  --no-tmux          Skip tmux session setup"
    echo "  --no-worktree      Skip git worktree setup"
    echo "  --help             Show this help"
    echo ""
    echo "Examples:"
    echo "  # Initialize in current directory"
    echo "  $0"
    echo ""
    echo "  # Initialize specific project"
    echo "  $0 /path/to/my-project --workers 2"
    echo ""
    echo "  # Initialize with custom model"
    echo "  $0 --model claude-4-sonnet"
    echo ""
}

# Parse arguments
PROJECT_PATH=""
WORKER_COUNT=3
MODEL="$DEFAULT_MODEL"
SETUP_TMUX=true
SETUP_WORKTREE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        --workers)
            WORKER_COUNT="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --no-tmux)
            SETUP_TMUX=false
            shift
            ;;
        --no-worktree)
            SETUP_WORKTREE=false
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            if [[ -z "$PROJECT_PATH" ]]; then
                PROJECT_PATH="$1"
            fi
            shift
            ;;
    esac
done

# Determine project path
if [[ -z "$PROJECT_PATH" ]]; then
    PROJECT_PATH=$(pwd)
fi

# Convert to absolute path
PROJECT_PATH=$(cd "$PROJECT_PATH" && pwd)

echo -e "${CYAN}🚀 Initializing Claude Multi-Agent System${NC}"
echo -e "${WHITE}Project: $PROJECT_PATH${NC}"
echo -e "${WHITE}Workers: $WORKER_COUNT${NC}"
echo -e "${WHITE}Model: $MODEL${NC}"
echo ""

# Step 1: Check prerequisites
echo -e "${BLUE}[1/5] Checking prerequisites...${NC}"

if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    exit 1
fi

if ! command -v tmux &> /dev/null && [[ "$SETUP_TMUX" == "true" ]]; then
    echo -e "${RED}Error: tmux is not installed${NC}"
    exit 1
fi

if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}Warning: claude CLI not found. Please install it first.${NC}"
    echo "Visit: https://docs.anthropic.com/en/docs/claude-code"
fi

echo -e "${GREEN}✓ Prerequisites checked${NC}"

# Step 2: Setup project structure
echo -e "\n${BLUE}[2/5] Setting up project structure...${NC}"

cd "$PROJECT_PATH"

# Check if it's a git repository
if ! git rev-parse --git-dir &> /dev/null; then
    echo -e "${YELLOW}Initializing git repository...${NC}"
    git init
fi

# Create .claude-multi-agent directory
mkdir -p .claude-multi-agent

# Create project config
cat > .claude-multi-agent/config.json <<EOF
{
  "project": {
    "name": "$(basename "$PROJECT_PATH")",
    "path": "$PROJECT_PATH",
    "created": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  },
  "workers": {
    "count": $WORKER_COUNT,
    "names": [$(seq -s, -f '"worker%g"' 1 $WORKER_COUNT)],
    "model": "$MODEL"
  },
  "git": {
    "branch_pattern": "$DEFAULT_BRANCH_PATTERN",
    "worktree_base": "worktrees"
  },
  "system": {
    "claude_system_root": "$SYSTEM_ROOT"
  }
}
EOF

echo -e "${GREEN}✓ Project structure created${NC}"

# Step 3: Setup git worktrees
if [[ "$SETUP_WORKTREE" == "true" ]]; then
    echo -e "\n${BLUE}[3/5] Setting up git worktrees...${NC}"
    
    export TARGET_PROJECT_ROOT="$PROJECT_PATH"
    "$SCRIPT_DIR/worktree-manager.sh" setup
    
    echo -e "${GREEN}✓ Git worktrees created${NC}"
else
    echo -e "\n${BLUE}[3/5] Skipping git worktree setup${NC}"
fi

# Step 4: Setup tmux session
if [[ "$SETUP_TMUX" == "true" ]]; then
    echo -e "\n${BLUE}[4/5] Setting up tmux session...${NC}"
    
    "$SCRIPT_DIR/setup-multiagent.sh"
    
    echo -e "${GREEN}✓ Tmux session created${NC}"
else
    echo -e "\n${BLUE}[4/5] Skipping tmux setup${NC}"
fi

# Step 5: Create helper scripts
echo -e "\n${BLUE}[5/5] Creating helper scripts...${NC}"

# Create start script
cat > "$PROJECT_PATH/.claude-multi-agent/start.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: config.json not found"
    exit 1
fi

SYSTEM_ROOT=$(jq -r '.system.claude_system_root' "$CONFIG_FILE")

if [[ ! -d "$SYSTEM_ROOT/scripts" ]]; then
    echo "Error: Claude Multi-Agent System not found at $SYSTEM_ROOT"
    exit 1
fi

cd "$SYSTEM_ROOT/scripts"
./quick-start-multiagent.sh
EOF

chmod +x "$PROJECT_PATH/.claude-multi-agent/start.sh"

# Create status script
cat > "$PROJECT_PATH/.claude-multi-agent/status.sh" <<'EOF'
#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$SCRIPT_DIR/config.json"
PROJECT_ROOT=$(jq -r '.project.path' "$CONFIG_FILE")
SYSTEM_ROOT=$(jq -r '.system.claude_system_root' "$CONFIG_FILE")

echo "📊 Project Status"
echo "=================="
echo "Project: $(jq -r '.project.name' "$CONFIG_FILE")"
echo "Path: $PROJECT_ROOT"
echo "Workers: $(jq -r '.workers.count' "$CONFIG_FILE")"
echo ""

# Check worktrees
echo "Git Worktrees:"
cd "$PROJECT_ROOT"
git worktree list

# Check tmux session
echo ""
echo "Tmux Session:"
if tmux has-session -t multiagent 2>/dev/null; then
    echo "✓ Session 'multiagent' is running"
else
    echo "✗ Session 'multiagent' is not running"
fi
EOF

chmod +x "$PROJECT_PATH/.claude-multi-agent/status.sh"

echo -e "${GREEN}✓ Helper scripts created${NC}"

# Final summary
echo -e "\n${GREEN}🎉 Initialization Complete!${NC}"
echo -e "\n${CYAN}Next Steps:${NC}"
echo "1. Create your planlist.md in the project root"
echo "2. Start the agents:"
echo "   ${WHITE}.claude-multi-agent/start.sh${NC}"
echo "3. Parse and assign tasks:"
echo "   ${WHITE}$SCRIPT_DIR/planlist-parser.sh assign $PROJECT_PATH/planlist.md${NC}"
echo "4. Monitor progress:"
echo "   ${WHITE}tmux attach -t multiagent${NC}"
echo ""
echo -e "${CYAN}Helper Commands:${NC}"
echo "  Check status: ${WHITE}.claude-multi-agent/status.sh${NC}"
echo "  Send message: ${WHITE}$SCRIPT_DIR/agent-send.sh worker1 \"Your message\"${NC}"
echo ""

# Add to gitignore
if [[ -f "$PROJECT_PATH/.gitignore" ]]; then
    if ! grep -q "worktrees/" "$PROJECT_PATH/.gitignore"; then
        echo -e "\n# Claude Multi-Agent System" >> "$PROJECT_PATH/.gitignore"
        echo "worktrees/" >> "$PROJECT_PATH/.gitignore"
        echo ".claude-multi-agent/logs/" >> "$PROJECT_PATH/.gitignore"
    fi
fi