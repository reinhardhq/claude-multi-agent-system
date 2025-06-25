#!/bin/bash
# ==============================================================================
# Monitor Dashboard - リアルタイム進捗モニタリング
# ==============================================================================
# Description: 各Workerの進捗状況をリアルタイムで監視・表示
# Usage: monitor-dashboard.sh [--interval SECONDS]
# Dependencies: git, tmux
# ==============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# Default interval
INTERVAL=5

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --interval|-i)
            INTERVAL="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Find project worktrees
find_worktrees() {
    local paths=(
        "$PWD/worktrees"
        "$PWD/../simple-weather-app/worktrees"
        "$SCRIPT_DIR/../simple-weather-app/worktrees"
    )
    
    for path in "${paths[@]}"; do
        if [[ -d "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Get git stats for a worktree
get_git_stats() {
    local worktree="$1"
    cd "$worktree" 2>/dev/null || return
    
    local branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    local commits=$(git log --oneline -n 10 2>/dev/null | wc -l | tr -d ' ')
    local changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    local additions=$(git diff --cached --numstat 2>/dev/null | awk '{sum+=$1} END {print sum+0}')
    local deletions=$(git diff --cached --numstat 2>/dev/null | awk '{sum+=$2} END {print sum+0}')
    
    echo "$branch|$commits|$changes|$additions|$deletions"
}

# Get file counts
get_file_counts() {
    local worktree="$1"
    cd "$worktree" 2>/dev/null || return
    
    local html_count=$(find . -name "*.html" -type f 2>/dev/null | wc -l | tr -d ' ')
    local js_count=$(find . -name "*.js" -o -name "*.jsx" -type f 2>/dev/null | wc -l | tr -d ' ')
    local css_count=$(find . -name "*.css" -type f 2>/dev/null | wc -l | tr -d ' ')
    local total_count=$(find . -type f -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | wc -l | tr -d ' ')
    
    echo "$html_count|$js_count|$css_count|$total_count"
}

# Draw progress bar
draw_progress_bar() {
    local percent=$1
    local width=20
    local filled=$((percent * width / 100))
    local empty=$((width - filled))
    
    printf "["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "]"
}

# Display dashboard
display_dashboard() {
    clear
    
    # Header
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}          📊 Claude Multi-Agent System - Progress Monitor          ${CYAN}║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Find worktrees
    local worktree_base=$(find_worktrees)
    if [[ -z "$worktree_base" ]]; then
        echo -e "${CYAN}║${RED} No worktrees found                                                ${CYAN}║${NC}"
        echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
        return
    fi
    
    # Time
    echo -e "${CYAN}║${NC} ${WHITE}Last Update:${NC} $(date '+%Y-%m-%d %H:%M:%S')                                   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Refresh Interval:${NC} ${INTERVAL}s                                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Check tmux session
    if tmux has-session -t multiagent 2>/dev/null; then
        echo -e "${CYAN}║${GREEN} ✓ Tmux Session Active${NC}                                             ${CYAN}║${NC}"
    else
        echo -e "${CYAN}║${RED} ✗ Tmux Session Not Running${NC}                                        ${CYAN}║${NC}"
    fi
    
    echo -e "${CYAN}╠════════════════════════════════════════════════════════════════════╣${NC}"
    
    # Worker status
    for worker in worker1 worker2 worker3; do
        local worktree="$worktree_base/$worker"
        
        if [[ -d "$worktree" ]]; then
            # Get stats
            local git_stats=$(get_git_stats "$worktree")
            IFS='|' read -r branch commits changes additions deletions <<< "$git_stats"
            
            local file_stats=$(get_file_counts "$worktree")
            IFS='|' read -r html_count js_count css_count total_count <<< "$file_stats"
            
            # Calculate progress (simple heuristic)
            local progress=0
            if [[ $total_count -gt 0 ]]; then
                progress=$((commits * 10 + total_count * 5))
                [[ $progress -gt 100 ]] && progress=100
            fi
            
            # Worker header
            case $worker in
                worker1) icon="🎨" ; name="UI/Frontend" ;;
                worker2) icon="⚙️ " ; name="Backend/Logic" ;;
                worker3) icon="🧪" ; name="Test/QA" ;;
            esac
            
            echo -e "${CYAN}║${NC} ${WHITE}${icon} ${worker^^} - ${name}${NC}                                    ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   Branch: ${GREEN}${branch}${NC}                                             ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   Progress: $(draw_progress_bar $progress) ${progress}%                        ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   Commits: ${BLUE}${commits}${NC} | Changes: ${YELLOW}${changes}${NC} | +${GREEN}${additions}${NC}/-${RED}${deletions}${NC}           ${CYAN}║${NC}"
            echo -e "${CYAN}║${NC}   Files: ${total_count} total (${html_count} HTML, ${js_count} JS, ${css_count} CSS)               ${CYAN}║${NC}"
            
            # Recent activity
            if [[ $commits -gt 0 ]]; then
                local last_commit=$(cd "$worktree" && git log -1 --pretty=format:"%s" 2>/dev/null | cut -c1-40)
                echo -e "${CYAN}║${NC}   Last: \"${last_commit}...\"                         ${CYAN}║${NC}"
            fi
        else
            echo -e "${CYAN}║${NC} ${RED}${worker^^} - Not Found${NC}                                            ${CYAN}║${NC}"
        fi
        
        if [[ "$worker" != "worker3" ]]; then
            echo -e "${CYAN}╟────────────────────────────────────────────────────────────────────╢${NC}"
        fi
    done
    
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════╝${NC}"
    
    # Instructions
    echo ""
    echo -e "${WHITE}Press Ctrl+C to exit${NC}"
}

# Main monitoring loop
echo -e "${CYAN}Starting Claude Multi-Agent Progress Monitor...${NC}"
echo -e "${WHITE}Refresh interval: ${INTERVAL} seconds${NC}"
echo ""

trap "echo -e '\n${GREEN}Monitor stopped.${NC}'; exit 0" INT TERM

while true; do
    display_dashboard
    sleep "$INTERVAL"
done