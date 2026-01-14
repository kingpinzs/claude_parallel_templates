#!/bin/bash
# Spec Kit Tasks Parallel Spawner
# Usage: spawn-tasks.sh [tasks-file]

set -e

# Find tasks file
if [[ -n "$1" ]] && [[ -f "$1" ]]; then
    TASKS_FILE="$1"
elif [[ -f ".spec/tasks.md" ]]; then
    TASKS_FILE=".spec/tasks.md"
elif [[ -f "tasks.md" ]]; then
    TASKS_FILE="tasks.md"
else
    echo "No tasks file found"
    exit 1
fi

PROJECT=$(basename "$(pwd)")
LOGS_DIR="../logs"
PIDS_FILE="../.parallel-pids"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[spec]${NC} $1"; }
warn() { echo -e "${YELLOW}[spec]${NC} $1"; }

# Load Spec Kit context
SPEC_CONTENT=""
PLAN_CONTENT=""
DESIGN_CONTENT=""

if [[ -f ".spec/spec.md" ]]; then
    log "Loading specification..."
    SPEC_CONTENT=$(cat .spec/spec.md)
else
    warn "No spec.md found - agents will have limited context"
fi

if [[ -f ".spec/plan.md" ]]; then
    log "Loading implementation plan..."
    PLAN_CONTENT=$(cat .spec/plan.md)
fi

if [[ -f ".spec/design.md" ]]; then
    log "Loading design decisions..."
    DESIGN_CONTENT=$(cat .spec/design.md)
fi

# Extract parallel tasks
log "Parsing tasks: $TASKS_FILE"

# Match tasks with [P] or (P) marker
TASKS=$(grep -E '^\s*-\s*\[\s*\].*\[P\]|^\s*-\s*\[\s*\].*\(P\)|^###.*\[P\]' "$TASKS_FILE" | \
        sed 's/^###\s*//' | \
        sed 's/^[^]]*\]//' | \
        sed 's/\[P\]//' | \
        sed 's/(P)//' | \
        sed 's/^\s*//' | \
        sed 's/\s*$//')

if [[ -z "$TASKS" ]]; then
    log "No parallel tasks found"
    log "Mark tasks with [P] to enable parallel execution"
    exit 0
fi

TASK_COUNT=$(echo "$TASKS" | wc -l)
log "Found $TASK_COUNT parallel tasks"

mkdir -p "$LOGS_DIR"
: > "$PIDS_FILE"

echo ""
log "Spawning Spec Kit tasks..."
echo ""

echo "$TASKS" | while IFS= read -r task; do
    [[ -z "$task" ]] && continue

    # Generate safe name
    name=$(echo "$task" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-25)
    worktree="../${PROJECT}-${name}"
    branch="feature/${name}"
    logfile="${LOGS_DIR}/${name}.log"

    log "Creating: $name"

    # Create worktree
    git worktree add "$worktree" -b "$branch" main 2>/dev/null || true

    # Spawn Claude with Spec Kit context
    (
        cd "$worktree"

        # Install dependencies
        [[ -f "package.json" ]] && npm install --silent 2>/dev/null || true
        [[ -f "requirements.txt" ]] && pip install -q -r requirements.txt 2>/dev/null || true

        # Build the prompt with full context
        PROMPT="You are a Spec Kit implementation agent.

## Your Task
$task

## Feature Specification
$SPEC_CONTENT

## Implementation Plan
$PLAN_CONTENT

## Design Decisions
$DESIGN_CONTENT

## Instructions
1. Implement ONLY the assigned task above
2. Follow the specification exactly
3. Adhere to the implementation plan
4. Write tests for any new functionality
5. Keep commits atomic: feat(spec): description
6. Do not modify unrelated files
7. Output 'TASK_COMPLETE' when finished

Begin implementation now."

        claude -p "$PROMPT" \
            --dangerously-skip-permissions \
            2>&1 | tee "$logfile"

        echo "TASK_COMPLETE: $name" >> "$logfile"
    ) &

    pid=$!
    echo "$pid:$name" >> "$PIDS_FILE"
    log "  PID: $pid → $worktree"
done

echo ""
log "All Spec Kit agents spawned!"
echo ""
echo "Tasks file: $TASKS_FILE"
echo "Spec loaded: $([ -n "$SPEC_CONTENT" ] && echo 'yes' || echo 'no')"
echo "Plan loaded: $([ -n "$PLAN_CONTENT" ] && echo 'yes' || echo 'no')"
echo ""
echo "Commands:"
echo "  tail -f $LOGS_DIR/*.log                    # Watch logs"
echo "  .claude/skills/parallel-executor/status.sh # Check status"
echo "  .claude/skills/parallel-executor/merge.sh  # Merge when done"
