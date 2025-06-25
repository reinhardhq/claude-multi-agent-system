# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

The Claude Multi-Agent System is an innovative framework that implements a hierarchical multi-agent AI system using Claude AI agents to collaboratively work on software development projects. The system uses tmux for session management and bash scripts for orchestration.

## High-Level Architecture

### Hierarchical 3-Layer Structure
```
👑 PRESIDENT (CEO/Strategic Decision Maker)
    ↓ Instructions & Vision
🎯 BOSS (Team Leader/Task Manager)
    ↓ Task Decomposition & Distribution
┌─────────────────────────────────────────┐
│ 🎨 WORKER1  │ ⚙️ WORKER2  │ 🧪 WORKER3  │
│ General Dev │ General Dev │ General Dev │
└─────────────────────────────────────────┘
```

### Two Usage Patterns

1. **AI President-Led Pattern**: User gives high-level requirements to AI President, which autonomously breaks down and delegates tasks through the hierarchy.

2. **Human President-Led Pattern**: Human creates detailed `planlist.md` and acts as Boss to directly control task distribution and implementation strategy.

## Common Development Commands

### Initial Setup for Any Project
```bash
# Option 1: Clone as subdirectory
cd /path/to/your/project
git clone https://github.com/your-repo/claude-multi-agent-system.git .claude-multi-agent

# Option 2: Clone elsewhere and add to PATH
git clone https://github.com/your-repo/claude-multi-agent-system.git ~/tools/claude-multi-agent
export PATH=$PATH:~/tools/claude-multi-agent/scripts

# Setup worktrees for your project
export TARGET_PROJECT_ROOT=$(pwd)
~/tools/claude-multi-agent/scripts/worktree-manager-improved.sh setup

# Setup tmux session and launch agents
cd ~/tools/claude-multi-agent/scripts
./setup-multiagent.sh
./quick-start-multiagent.sh
```

### Communication
```bash
# Send messages to specific agents
./agent-send.sh president "Create a TODO app"
./agent-send.sh boss "Distribute tasks to workers"
./agent-send.sh worker1 "Implement UI components"
./agent-send.sh team "Report progress"
./agent-send.sh all "Emergency meeting"
```

### Management Commands
```bash
# Boss operations
./boss-commander.sh analyze    # Analyze planlist
./boss-commander.sh assign     # Distribute tasks
./boss-commander.sh check      # Check progress
./boss-commander.sh review worker1  # Review work

# Worktree management (improved version)
./worktree-manager-improved.sh info    # Show project info
./worktree-manager-improved.sh setup   # Setup all worktrees
./worktree-manager-improved.sh status  # Check worker status

# Progress tracking
./progress-tracker.sh request all standard
./progress-tracker.sh monitor

# Parallel development
./parallel-dev-manager.sh merge-all
```

### tmux Navigation
- `Ctrl+B → 0`: Switch to PRESIDENT window
- `Ctrl+B → 1`: Switch to team window (4-pane)
- `Ctrl+B → arrow keys`: Navigate between panes
- `Ctrl+B → d`: Detach from session

## Code Architecture and Structure

### Directory Structure
- `president/`: President role definition and documentation
- `boss/`: Boss role definition and management guidelines
- `worker/`: Worker role definitions (general development)
- `scripts/`: Core automation and orchestration scripts
- `assignments/`: Task assignments for workers
- `reports/`: Progress reports and analyses
- `planlist.md`: Project plan template (for human-led pattern)

### Key Scripts
- `setup-multiagent.sh`: Creates tmux session structure
- `quick-start-multiagent.sh`: Launches Claude AI agents
- `agent-send.sh`: Routes messages to specific agents/groups
- `boss-commander.sh`: Boss control panel for task management
- `worktree-manager-improved.sh`: Manages git worktrees for any project
- `parallel-dev-manager.sh`: Manages parallel development branches
- `progress-tracker.sh`: Monitors and reports progress

### Role Responsibilities

**President**: Strategic vision, 5-layer needs analysis, quality standards, final approval
**Boss**: Task decomposition, 10-minute progress checks, team facilitation, reporting
**Workers**: Flexible role adaptation, quality implementation, collaborative development

### Project Plan Format (planlist.md)
```markdown
## Project Overview
**Project Name**: [Name]
**Deadline**: [Date]
**Goal**: [Main objectives]

## Approach N: [Technology Stack]
### Basic Info (Required)
**Overview**: [One-line description]
**Tech Stack**: [Technologies]
**Assigned Worker**: [worker1/2/3]
**Priority**: [High/Medium/Low]
**Estimated Hours**: [Number]

### Implementation Details
[Flexible content based on project needs]
```

## Development Workflow

### AI President-Led Workflow
1. User provides high-level requirements to President
2. President creates vision and strategy
3. Boss receives instructions and decomposes tasks
4. Workers implement in parallel
5. Regular progress checks and integration

### Human President-Led Workflow
1. Human creates detailed `planlist.md`
2. Uses boss-commander to distribute tasks
3. Provides specific instructions to workers
4. Monitors progress and provides feedback
5. Controls integration and quality

### Progress Reporting
- Workers report every 10 minutes (Boss's rule)
- Structured progress format in reports/
- Comparison analyses for multiple approaches
- Quality metrics and completion tracking

## Testing and Quality

- Each worker ensures quality in their domain
- Regular progress checks and reviews
- Integration testing during merge phases
- Final validation against requirements

### Git Worktree Support for Any Project
The system supports working with any Git project through environment variables:
- `TARGET_PROJECT_ROOT`: The root directory of your project
- `WORKTREE_BASE`: Where to create worker worktrees (default: `$PROJECT_ROOT/worktrees`)

Each worker gets an independent worktree:
- Worker1: `feature/worker-worker1-dev`
- Worker2: `feature/worker-worker2-dev`
- Worker3: `feature/worker-worker3-dev`

## Important Notes

- This is a pure orchestration system (no package.json)
- Requires Claude CLI installed and authenticated
- Designed for macOS/Linux with tmux
- Mixed Japanese/English documentation
- Focus on AI agent collaboration patterns
- Supports any Git project through environment variables