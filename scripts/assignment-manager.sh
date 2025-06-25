#!/bin/bash
# ==============================================================================
# Assignment Manager - タイムスタンプベースタスク管理システム
# ==============================================================================
# Description: タイムスタンプベースでassignmentsを整理・管理しノイズを削減
# Usage: assignment-manager.sh [init|create|clean|archive|list]
# Dependencies: None
# ==============================================================================

set -e

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SYSTEM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Paths
ASSIGNMENTS_BASE="$CLAUDE_SYSTEM_ROOT/assignments"
REPORTS_BASE="$CLAUDE_SYSTEM_ROOT/reports"
CURRENT_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CURRENT_DATE=$(date +"%Y%m%d")

# Create timestamp-based assignment directory
create_assignment_dir() {
    local assignment_dir="$ASSIGNMENTS_BASE/$CURRENT_DATE/$CURRENT_TIMESTAMP"
    mkdir -p "$assignment_dir"
    echo "$assignment_dir"
}

# Create timestamp-based report directory
create_report_dir() {
    local report_dir="$REPORTS_BASE/$CURRENT_DATE/$CURRENT_TIMESTAMP"
    mkdir -p "$report_dir"
    echo "$report_dir"
}

# Create assignment file
create_assignment() {
    local worker=$1
    local approach=$2
    local content=$3
    local assignment_dir=$(create_assignment_dir)
    local assignment_file="$assignment_dir/${worker}_approach_${approach}.md"
    
    echo -e "${BLUE}📝 Creating assignment for $worker...${NC}"
    
    cat > "$assignment_file" << EOF
# 🎯 方式案${approach}分配書

**担当Worker**: $worker
**分配日時**: $(date +"%Y-%m-%d %H:%M:%S")
**分配者**: BOSS
**作業ディレクトリ**: /tmp/worker-outputs/$worker/$CURRENT_TIMESTAMP

---

## 📋 方式案詳細

$content

---

## 🗂️ 作業ガイドライン

### 中間成果物の保存場所
全ての中間成果物は以下のディレクトリに保存してください：
\`\`\`
/tmp/worker-outputs/$worker/$CURRENT_TIMESTAMP/
├── src/           # ソースコード
├── docs/          # ドキュメント
├── tests/         # テストコード
└── build/         # ビルド成果物
\`\`\`

### 最終成果物の提出
完成したコードは worktree の feature ブランチにコミットしてください：
\`\`\`bash
cd $(git rev-parse --show-toplevel)/worktrees/$worker
git add .
git commit -m "Implement approach $approach"
git push origin feature/worker-$worker-dev
\`\`\`

### 進捗報告
定期的に進捗を報告してください：
\`\`\`
$REPORTS_BASE/$CURRENT_DATE/$CURRENT_TIMESTAMP/${worker}_progress.md
\`\`\`

---

## ⚠️ 注意事項

1. **中間成果物は /tmp に保存**: メインリポジトリを汚さないようにしてください
2. **定期的なバックアップ**: /tmp は再起動で消えるため、重要なものは適宜コミット
3. **ブランチの独立性**: 他のWorkerの作業に影響を与えないよう注意
EOF

    echo -e "${GREEN}✅ Assignment created: $assignment_file${NC}"
    
    # Create worker's tmp directory
    local worker_tmp="/tmp/worker-outputs/$worker/$CURRENT_TIMESTAMP"
    mkdir -p "$worker_tmp/src" "$worker_tmp/docs" "$worker_tmp/tests" "$worker_tmp/build"
    echo -e "${GREEN}✅ Work directory created: $worker_tmp${NC}"
    
    # Create symlink for current assignment
    local current_link="$ASSIGNMENTS_BASE/current"
    rm -f "$current_link"
    ln -s "$assignment_dir" "$current_link"
    
    echo "$assignment_file"
}

# List assignments by date
list_assignments() {
    echo -e "${CYAN}📋 Assignment History${NC}"
    echo ""
    
    if [ ! -d "$ASSIGNMENTS_BASE" ]; then
        echo -e "${YELLOW}No assignments found${NC}"
        return
    fi
    
    # List by date
    for date_dir in $(ls -dr "$ASSIGNMENTS_BASE"/[0-9]* 2>/dev/null); do
        if [ -d "$date_dir" ]; then
            local date=$(basename "$date_dir")
            echo -e "${WHITE}📅 $date${NC}"
            
            # List timestamps for this date
            for time_dir in $(ls -dr "$date_dir"/[0-9]* 2>/dev/null); do
                if [ -d "$time_dir" ]; then
                    local timestamp=$(basename "$time_dir")
                    echo -e "  ${BLUE}⏰ $timestamp${NC}"
                    
                    # List assignments in this timestamp
                    for assignment in "$time_dir"/*.md; do
                        if [ -f "$assignment" ]; then
                            echo -e "    ${GREEN}📄 $(basename "$assignment")${NC}"
                        fi
                    done
                fi
            done
            echo ""
        fi
    done
    
    # Show current assignment
    if [ -L "$ASSIGNMENTS_BASE/current" ]; then
        echo -e "${YELLOW}📌 Current Assignment:${NC}"
        echo -e "  $(readlink "$ASSIGNMENTS_BASE/current")"
    fi
}

# Clean old assignments
clean_old_assignments() {
    local days_to_keep=${1:-7}
    echo -e "${CYAN}🧹 Cleaning assignments older than $days_to_keep days...${NC}"
    
    if [ ! -d "$ASSIGNMENTS_BASE" ]; then
        echo -e "${YELLOW}No assignments to clean${NC}"
        return
    fi
    
    # Find and remove old directories
    find "$ASSIGNMENTS_BASE" -type d -name "[0-9]*" -mtime +$days_to_keep -exec rm -rf {} + 2>/dev/null || true
    
    # Clean empty date directories
    find "$ASSIGNMENTS_BASE" -type d -empty -delete 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Archive assignments
archive_assignments() {
    local archive_name="assignments_archive_$(date +%Y%m%d_%H%M%S).tar.gz"
    local archive_path="$CLAUDE_SYSTEM_ROOT/archives/$archive_name"
    
    mkdir -p "$CLAUDE_SYSTEM_ROOT/archives"
    
    echo -e "${CYAN}📦 Archiving assignments...${NC}"
    
    if [ ! -d "$ASSIGNMENTS_BASE" ]; then
        echo -e "${YELLOW}No assignments to archive${NC}"
        return
    fi
    
    tar -czf "$archive_path" -C "$CLAUDE_SYSTEM_ROOT" assignments/
    echo -e "${GREEN}✅ Archived to: $archive_path${NC}"
}

# Show usage
show_usage() {
    echo -e "${CYAN}📋 Assignment Manager${NC}"
    echo ""
    echo "Manages assignments with timestamp-based organization"
    echo ""
    echo "Usage:"
    echo "  $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo -e "  ${GREEN}create${NC} <worker> <approach>  - Create new assignment"
    echo -e "  ${GREEN}list${NC}                        - List all assignments"
    echo -e "  ${GREEN}clean${NC} [days]                - Clean old assignments (default: 7 days)"
    echo -e "  ${GREEN}archive${NC}                     - Archive all assignments"
    echo ""
    echo "Example:"
    echo "  $0 create worker1 1"
    echo "  $0 list"
    echo "  $0 clean 30"
    echo ""
}

# Main logic
case "$1" in
    create)
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}❌ Usage: $0 create <worker> <approach>${NC}"
            exit 1
        fi
        
        # Read content from stdin or use placeholder
        if [ -t 0 ]; then
            content="[Assignment content will be added here]"
        else
            content=$(cat)
        fi
        
        create_assignment "$2" "$3" "$content"
        ;;
    
    list)
        list_assignments
        ;;
    
    clean)
        clean_old_assignments "${2:-7}"
        ;;
    
    archive)
        archive_assignments
        ;;
    
    help|--help|-h|*)
        show_usage
        ;;
esac