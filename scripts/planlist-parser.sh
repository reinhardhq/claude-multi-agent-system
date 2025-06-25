#!/bin/bash
# ==============================================================================
# Planlist Parser - 柔軟なplanlist.md解析ツール
# ==============================================================================
# Description: 様々なフォーマットのplanlist.mdを解析してワーカー割り当てを行う
# Usage: planlist-parser.sh [parse|assign|check] [planlist.md]
# Dependencies: jq, curl
# ==============================================================================

set -euo pipefail

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Default planlist path
DEFAULT_PLANLIST="$PROJECT_ROOT/planlist.md"

# Usage
show_usage() {
    echo -e "${CYAN}📋 Planlist Parser - 柔軟なplanlist.md解析ツール${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 parse [planlist.md]   - planlist.mdを解析"
    echo "  $0 assign [planlist.md]  - タスクをWorkerに割り当て"
    echo "  $0 check                 - 現在の割り当て状況を確認"
    echo ""
    echo "Supported Formats:"
    echo "  - ## Approach N: Title"
    echo "  - ## 方式案N: Title"
    echo "  - ## Option N: Title"
    echo ""
}

# Find planlist.md in various locations
find_planlist() {
    local custom_path="$1"
    
    if [[ -n "$custom_path" && -f "$custom_path" ]]; then
        echo "$custom_path"
        return 0
    fi
    
    # Search in common locations
    local search_paths=(
        "$PROJECT_ROOT/planlist.md"
        "$PROJECT_ROOT/../planlist.md"
        "$PROJECT_ROOT/simple-weather-app/planlist.md"
        "$(pwd)/planlist.md"
    )
    
    for path in "${search_paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done
    
    return 1
}

# Parse approach/option blocks
parse_approaches() {
    local planlist="$1"
    local temp_file="/tmp/planlist_parsed.json"
    
    # Initialize JSON array
    echo "[]" > "$temp_file"
    
    # Find all approach patterns
    local approach_count=0
    
    # Pattern 1: ## Approach N:
    while IFS= read -r line; do
        if [[ "$line" =~ ^##[[:space:]]+(Approach|方式案|Option)[[:space:]]+([0-9]+):[[:space:]]*(.*) ]]; then
            local approach_type="${BASH_REMATCH[1]}"
            local approach_num="${BASH_REMATCH[2]}"
            local approach_title="${BASH_REMATCH[3]}"
            
            echo -e "${BLUE}Found: $approach_type $approach_num - $approach_title${NC}"
            
            # Extract details for this approach
            local details=$(extract_approach_details "$planlist" "$approach_num" "$approach_type")
            
            # Add to JSON
            jq --arg num "$approach_num" \
               --arg title "$approach_title" \
               --arg type "$approach_type" \
               --argjson details "$details" \
               '. += [{
                   "number": $num,
                   "title": $title,
                   "type": $type,
                   "details": $details
               }]' "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
            
            ((approach_count++))
        fi
    done < "$planlist"
    
    echo -e "${GREEN}Total approaches found: $approach_count${NC}"
    cat "$temp_file"
}

# Extract details for a specific approach
extract_approach_details() {
    local planlist="$1"
    local approach_num="$2"
    local approach_type="$3"
    
    local temp_section="/tmp/approach_${approach_num}_section.txt"
    
    # Extract section between this approach and the next
    awk -v num="$approach_num" -v type="$approach_type" '
        /^## (Approach|方式案|Option) / { 
            if (found) exit; 
            if ($2 " " $3 == type " " num ":") found=1; 
        }
        found { print }
    ' "$planlist" > "$temp_section"
    
    # Extract key fields
    local overview=$(grep -i "^\*\*Overview\*\*:" "$temp_section" 2>/dev/null | sed 's/.*: *//' | head -1 || echo "")
    local tech_stack=$(grep -i "^\*\*Tech Stack\*\*:" "$temp_section" 2>/dev/null | sed 's/.*: *//' | head -1 || echo "")
    local assigned_worker=$(grep -i "^\*\*Assigned Worker\*\*:" "$temp_section" 2>/dev/null | sed 's/.*: *//' | head -1 || echo "")
    local priority=$(grep -i "^\*\*Priority\*\*:" "$temp_section" 2>/dev/null | sed 's/.*: *//' | head -1 || echo "")
    local estimated_hours=$(grep -i "^\*\*Estimated Hours\*\*:" "$temp_section" 2>/dev/null | sed 's/.*: *//' | head -1 || echo "")
    
    # Create JSON object
    jq -n \
        --arg overview "$overview" \
        --arg tech_stack "$tech_stack" \
        --arg assigned_worker "$assigned_worker" \
        --arg priority "$priority" \
        --arg estimated_hours "$estimated_hours" \
        '{
            "overview": $overview,
            "tech_stack": $tech_stack,
            "assigned_worker": $assigned_worker,
            "priority": $priority,
            "estimated_hours": $estimated_hours
        }'
    
    rm -f "$temp_section"
}

# Assign tasks to workers
assign_tasks() {
    local planlist="$1"
    local parsed_data="/tmp/planlist_parsed.json"
    
    # Parse planlist first
    parse_approaches "$planlist" > "$parsed_data"
    
    echo -e "\n${CYAN}📤 Assigning tasks to workers...${NC}\n"
    
    # Read each approach and send to assigned worker
    local approach_count=$(jq 'length' "$parsed_data")
    
    for ((i=0; i<$approach_count; i++)); do
        local approach=$(jq -r ".[$i]" "$parsed_data")
        local number=$(echo "$approach" | jq -r '.number')
        local title=$(echo "$approach" | jq -r '.title')
        local worker=$(echo "$approach" | jq -r '.details.assigned_worker')
        local overview=$(echo "$approach" | jq -r '.details.overview')
        
        if [[ -n "$worker" && "$worker" != "null" && "$worker" != "" ]]; then
            echo -e "${GREEN}Assigning Approach $number to $worker${NC}"
            echo "  Title: $title"
            echo "  Overview: $overview"
            
            # Find worker's worktree path
            local worktree_path=""
            if [[ -d "$PROJECT_ROOT/simple-weather-app/worktrees/$worker" ]]; then
                worktree_path="$PROJECT_ROOT/simple-weather-app/worktrees/$worker"
            elif [[ -d "$PROJECT_ROOT/../simple-weather-app/worktrees/$worker" ]]; then
                worktree_path="$PROJECT_ROOT/../simple-weather-app/worktrees/$worker"
            fi
            
            if [[ -n "$worktree_path" ]]; then
                # Create assignment message
                local message="あなたは${worker}です。Approach ${number}: ${title} を実装してください。作業ディレクトリ: ${worktree_path}。planlist.mdの詳細に従って実装を進めてください。"
                
                # Send message using agent-send.sh
                if [[ -f "$SCRIPT_DIR/agent-send.sh" ]]; then
                    "$SCRIPT_DIR/agent-send.sh" "$worker" "$message"
                else
                    echo -e "${YELLOW}Warning: agent-send.sh not found${NC}"
                fi
            else
                echo -e "${YELLOW}Warning: Worktree not found for $worker${NC}"
            fi
            
            echo ""
        else
            echo -e "${YELLOW}No worker assigned for Approach $number${NC}"
        fi
    done
    
    rm -f "$parsed_data"
}

# Check current assignments
check_assignments() {
    echo -e "${CYAN}📊 Current Task Assignments${NC}\n"
    
    # Check each worker's status
    for worker in worker1 worker2 worker3; do
        echo -e "${WHITE}=== $worker ===${NC}"
        
        # Check if worker has a worktree
        local worktree_paths=(
            "$PROJECT_ROOT/simple-weather-app/worktrees/$worker"
            "$PROJECT_ROOT/../simple-weather-app/worktrees/$worker"
        )
        
        local found=false
        for path in "${worktree_paths[@]}"; do
            if [[ -d "$path" ]]; then
                found=true
                echo "  Worktree: $path"
                
                # Check git status
                if cd "$path" 2>/dev/null; then
                    local branch=$(git branch --show-current 2>/dev/null)
                    local changes=$(git status --porcelain 2>/dev/null | wc -l)
                    echo "  Branch: $branch"
                    echo "  Changes: $changes files modified"
                fi
                
                break
            fi
        done
        
        if [[ "$found" == "false" ]]; then
            echo "  Status: No worktree found"
        fi
        
        echo ""
    done
}

# Main logic
case "${1:-help}" in
    parse)
        planlist_path=$(find_planlist "${2:-}")
        if [[ -z "$planlist_path" ]]; then
            echo -e "${RED}Error: planlist.md not found${NC}"
            exit 1
        fi
        echo -e "${GREEN}Using planlist: $planlist_path${NC}\n"
        parse_approaches "$planlist_path"
        ;;
    
    assign)
        planlist_path=$(find_planlist "${2:-}")
        if [[ -z "$planlist_path" ]]; then
            echo -e "${RED}Error: planlist.md not found${NC}"
            exit 1
        fi
        echo -e "${GREEN}Using planlist: $planlist_path${NC}"
        assign_tasks "$planlist_path"
        ;;
    
    check)
        check_assignments
        ;;
    
    help|--help|-h|*)
        show_usage
        ;;
esac