#!/bin/bash
# Parallel Claude Code Spawner
# Usage: spawn.sh "task1" "task2" "task3"
# Or:    spawn.sh --file tasks.md

set -e

PROJECT=$(basename $(pwd))
LOGS_DIR="../logs"
PIDS_FILE="../.parallel-pids"
MAX_PARALLEL=10

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[spawn]${NC} $1"; }
warn() { echo -e "${YELLOW}[spawn]${NC} $1"; }
error() { echo -e "${RED}[spawn]${NC} $1"; exit 1; }

# Parse arguments
TASKS=()
if [[ "$1" == "--file" ]]; then
    [[ -f "$2" ]] || error "File not found: $2"
    # Extract tasks marked with [P] or (P)
    while IFS= read -r line; do
        if [[ "$line" =~ \[P\]|\(P\) ]]; then
            # Clean up the task description
            task=$(echo "$line" | sed 's/^[^a-zA-Z]*//' | sed 's/\[P\]//' | sed 's/(P)//' | xargs)
            [[ -n "$task" ]] && TASKS+=("$task")
        fi
    done < "$2"
else
    TASKS=("$@")
fi

# Validate
[[ ${#TASKS[@]} -eq 0 ]] && error "No tasks provided"
[[ ${#TASKS[@]} -gt $MAX_PARALLEL ]] && error "Too many tasks (max $MAX_PARALLEL)"

# Setup
mkdir -p "$LOGS_DIR"
> "$PIDS_FILE"

log "Spawning ${#TASKS[@]} parallel agents..."
echo ""

# Spawn each task
for task in "${TASKS[@]}"; do
    # Generate safe name
    name=$(echo "$task" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-25)
    worktree="../${PROJECT}-${name}"
    branch="feature/${name}"
    logfile="${LOGS_DIR}/${name}.log"

    log "Creating worktree: $worktree"

    # Create worktree
    if ! git worktree add "$worktree" -b "$branch" main 2>/dev/null; then
        warn "Worktree exists, reusing: $worktree"
    fi

    # Spawn Claude in background
    (
        cd "$worktree"

        # Install dependencies if needed
        [[ -f "package.json" ]] && npm install --silent 2>/dev/null || true
        [[ -f "requirements.txt" ]] && pip install -q -r requirements.txt 2>/dev/null || true

        # Run Claude headless
        claude -p "Implement this task: $task

Instructions:
1. Follow project conventions in CLAUDE.md
2. Write clean, tested code
3. Commit your changes with a descriptive message
4. Output 'TASK_COMPLETE' when finished

Begin implementation." \
            --dangerously-skip-permissions \
            2>&1 | tee "$logfile"

        echo "TASK_COMPLETE: $name" >> "$logfile"
    ) &

    pid=$!
    echo "$pid:$name" >> "$PIDS_FILE"
    log "  Spawned: $name (PID: $pid)"
done

echo ""
log "All agents spawned!"
echo ""
echo "Monitor commands:"
echo "  tail -f $LOGS_DIR/*.log              # Watch all logs"
echo "  $(dirname $0)/status.sh              # Check completion"
echo "  wait \$(cut -d: -f1 $PIDS_FILE)       # Wait for all"
echo ""
echo "When complete:"
echo "  $(dirname $0)/merge.sh               # Merge all to main"
