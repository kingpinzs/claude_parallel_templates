#!/bin/bash
# Parallel Claude Code Spawner
# Usage: spawn.sh "task1" "task2" "task3"
# Or:    spawn.sh --file tasks.md
# Or:    spawn.sh --scoped "task1|scope1" "task2|scope2"
# Options:
#   --no-orchestrate    Don't auto-start orchestrator
#   --no-auto-merge     Start orchestrator but don't auto-merge
#   --max-turns=N       Max turns per agent (default: 100)
#   --scoped            Tasks include scope (format: "task|scope")

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT=$(basename $(pwd))
LOGS_DIR="../logs"
PIDS_FILE="../.parallel-pids"
SCOPES_FILE="../.parallel-scopes"
MAX_PARALLEL=10
MAX_TURNS=100
AUTO_ORCHESTRATE=true
AUTO_MERGE=true
SCOPED_MODE=false

# Check if ralph-wiggum plugin is available
RALPH_AVAILABLE=false
if claude plugin list 2>/dev/null | grep -q "ralph-wiggum"; then
    RALPH_AVAILABLE=true
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[spawn]${NC} $1"; }
warn() { echo -e "${YELLOW}[spawn]${NC} $1"; }
error() { echo -e "${RED}[spawn]${NC} $1"; exit 1; }

# Check for Claude CLI
if ! command -v claude &> /dev/null; then
    error "Claude Code CLI not found. Install it first: https://docs.anthropic.com/en/docs/claude-code"
fi

# Parse arguments
TASKS=()
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-orchestrate)
            AUTO_ORCHESTRATE=false
            shift
            ;;
        --no-auto-merge)
            AUTO_MERGE=false
            shift
            ;;
        --max-turns=*)
            MAX_TURNS="${1#*=}"
            shift
            ;;
        --scoped)
            SCOPED_MODE=true
            shift
            ;;
        --file)
            [[ -f "$2" ]] || error "File not found: $2"
            # Extract tasks marked with [P] or (P)
            # Format: "- [ ] Task description [P] → scope: src/dir/"
            while IFS= read -r line; do
                if [[ "$line" =~ \[P\]|\(P\) ]]; then
                    # Extract scope if present (after "→ scope:" or "scope:")
                    scope=""
                    if [[ "$line" =~ →[[:space:]]*scope:[[:space:]]*([^[:space:]]+) ]]; then
                        scope="${BASH_REMATCH[1]}"
                        SCOPED_MODE=true
                    elif [[ "$line" =~ scope:[[:space:]]*([^[:space:]]+) ]]; then
                        scope="${BASH_REMATCH[1]}"
                        SCOPED_MODE=true
                    fi
                    # Clean up the task description (remove [P], scope info)
                    task=$(echo "$line" | sed 's/^[^a-zA-Z]*//' | sed 's/\[P\]//' | sed 's/(P)//' | sed 's/→.*$//' | sed 's/scope:[^[:space:]]*//' | xargs)
                    if [[ -n "$task" ]]; then
                        if [[ -n "$scope" ]]; then
                            TASKS+=("$task|$scope")
                        else
                            TASKS+=("$task")
                        fi
                    fi
                fi
            done < "$2"
            shift 2
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

# Add positional args as tasks
TASKS+=("${POSITIONAL[@]}")

# Validate
[[ ${#TASKS[@]} -eq 0 ]] && error "No tasks provided"
[[ ${#TASKS[@]} -gt $MAX_PARALLEL ]] && error "Too many tasks (max $MAX_PARALLEL)"

# Setup
mkdir -p "$LOGS_DIR"
> "$PIDS_FILE"
> "$SCOPES_FILE"

log "Spawning ${#TASKS[@]} parallel agents..."
if $SCOPED_MODE; then
    log "File scope enforcement: ENABLED"
fi
echo ""

# Spawn each task
for task_entry in "${TASKS[@]}"; do
    # Parse task and scope (format: "task|scope" or just "task")
    if [[ "$task_entry" == *"|"* ]]; then
        task="${task_entry%%|*}"
        scope="${task_entry#*|}"
    else
        task="$task_entry"
        scope="*"  # No restriction
    fi

    # Generate safe name
    name=$(echo "$task" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]//g' | cut -c1-25)
    worktree="../${PROJECT}-${name}"
    branch="feature/${name}"
    logfile="${LOGS_DIR}/${name}.log"

    log "Creating worktree: $worktree"
    if [[ "$scope" != "*" ]]; then
        log "  Scope: $scope"
    fi

    # Record scope for conflict detection
    echo "$name:$scope" >> "$SCOPES_FILE"

    # Create worktree
    if ! git worktree add "$worktree" -b "$branch" main 2>/dev/null; then
        warn "Worktree exists, reusing: $worktree"
    fi

    # Build prompt from template with task and scope
    PROMPT=$(cat "$SCRIPT_DIR/agent-prompt.md" | sed "s|{{TASK}}|$task|g" | sed "s|{{SCOPE}}|$scope|g")

    # Create a runner script for this agent (ensures proper detachment)
    runner_script="${LOGS_DIR}/${name}-runner.sh"
    cat > "$runner_script" << RUNNER_EOF
#!/bin/bash
cd "$worktree"

# Install dependencies if needed
[[ -f "package.json" ]] && npm install --silent 2>/dev/null || true
[[ -f "requirements.txt" ]] && pip install -q -r requirements.txt 2>/dev/null || true

# Run Claude headless with structured methodology
claude -p '$PROMPT' \\
    --dangerously-skip-permissions \\
    --max-turns $MAX_TURNS \\
    > "$logfile" 2>&1

echo "TASK_COMPLETE: $name" >> "$logfile"
RUNNER_EOF
    chmod +x "$runner_script"

    # Spawn fully detached using nohup + disown
    nohup bash "$runner_script" > /dev/null 2>&1 &
    pid=$!
    disown $pid

    echo "$pid:$name" >> "$PIDS_FILE"
    log "  Spawned: $name (PID: $pid)"
done

echo ""
log "All ${#TASKS[@]} agents spawned!"
echo ""

# Auto-start orchestrator
if $AUTO_ORCHESTRATE; then
    echo "═══════════════════════════════════════════════════════════"
    log "Starting orchestrator (auto-merge: $AUTO_MERGE)..."
    echo ""

    if $AUTO_MERGE; then
        # Run orchestrator with auto-merge
        exec "$SCRIPT_DIR/orchestrate.sh" --auto-merge
    else
        # Run orchestrator without auto-merge
        exec "$SCRIPT_DIR/orchestrate.sh"
    fi
else
    echo "Monitor commands:"
    echo "  tail -f $LOGS_DIR/*.log              # Watch all logs"
    echo "  $SCRIPT_DIR/status.sh                # Check completion"
    echo "  $SCRIPT_DIR/orchestrate.sh           # Start orchestrator"
    echo ""
    echo "When complete:"
    echo "  $SCRIPT_DIR/merge.sh                 # Merge all to main"
fi
