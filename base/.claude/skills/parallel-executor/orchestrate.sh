#!/bin/bash
# Orchestrator: Monitor parallel agents and merge when all complete
# Usage: orchestrate.sh [--auto-merge] [--poll-interval=30]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PIDS_FILE="../.parallel-pids"
LOGS_DIR="../logs"
AUTO_MERGE=false
POLL_INTERVAL=30

# Parse arguments
for arg in "$@"; do
    case $arg in
        --auto-merge)
            AUTO_MERGE=true
            ;;
        --poll-interval=*)
            POLL_INTERVAL="${arg#*=}"
            ;;
    esac
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[orchestrate]${NC} $1"; }
warn() { echo -e "${YELLOW}[orchestrate]${NC} $1"; }
error() { echo -e "${RED}[orchestrate]${NC} $1"; }

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "               PARALLEL AGENT ORCHESTRATOR"
echo "═══════════════════════════════════════════════════════════"
echo ""
log "Auto-merge: $AUTO_MERGE"
log "Poll interval: ${POLL_INTERVAL}s"
echo ""

if [[ ! -f "$PIDS_FILE" ]]; then
    error "No parallel agents found (no PID file at $PIDS_FILE)"
    exit 1
fi

# Count total agents
TOTAL=$(wc -l < "$PIDS_FILE")
log "Monitoring $TOTAL parallel agents..."
echo ""

# Function to check agent status
check_status() {
    local running=0
    local completed=0
    local failed=0

    while IFS=: read -r pid name; do
        logfile="${LOGS_DIR}/${name}.log"

        if kill -0 "$pid" 2>/dev/null; then
            ((running++))
        elif [[ -f "$logfile" ]] && grep -qi "error\|failed\|exception\|panic" "$logfile" 2>/dev/null; then
            ((failed++))
        else
            ((completed++))
        fi
    done < "$PIDS_FILE"

    echo "$running:$completed:$failed"
}

# Function to show progress
show_progress() {
    local running=$1
    local completed=$2
    local failed=$3
    local timestamp=$(date '+%H:%M:%S')

    printf "\r[%s] " "$timestamp"
    printf "${GREEN}%d/%d complete${NC} " "$completed" "$TOTAL"
    printf "${YELLOW}%d running${NC} " "$running"
    if [[ $failed -gt 0 ]]; then
        printf "${RED}%d failed${NC}" "$failed"
    fi
}

# Monitor loop
start_time=$(date +%s)
while true; do
    IFS=: read -r running completed failed <<< "$(check_status)"

    show_progress "$running" "$completed" "$failed"

    # Check if all done
    if [[ $running -eq 0 ]]; then
        echo ""
        echo ""

        elapsed=$(($(date +%s) - start_time))
        minutes=$((elapsed / 60))
        seconds=$((elapsed % 60))

        echo "═══════════════════════════════════════════════════════════"
        log "All agents finished in ${minutes}m ${seconds}s"
        echo ""

        if [[ $failed -gt 0 ]]; then
            error "$failed agent(s) failed. Check logs:"
            echo ""
            while IFS=: read -r pid name; do
                logfile="${LOGS_DIR}/${name}.log"
                if [[ -f "$logfile" ]] && grep -qi "error\|failed\|exception\|panic" "$logfile" 2>/dev/null; then
                    echo "  ${RED}✗${NC} $name: $logfile"
                    # Show last error line
                    grep -i "error\|failed\|exception\|panic" "$logfile" 2>/dev/null | tail -1 | sed 's/^/    /'
                fi
            done < "$PIDS_FILE"
            echo ""
            echo "Fix issues and re-run, or proceed with successful agents."
            exit 1
        fi

        echo "${GREEN}✓${NC} All $completed agents completed successfully!"
        echo ""

        # Show what was completed
        echo "Completed worktrees:"
        while IFS=: read -r pid name; do
            echo "  ${GREEN}✓${NC} $name"
        done < "$PIDS_FILE"
        echo ""

        if $AUTO_MERGE; then
            log "Auto-merge enabled. Starting merge..."
            echo ""
            "$SCRIPT_DIR/merge.sh" --cleanup
        else
            echo "Next steps:"
            echo "  1. Review changes: git -C ../<worktree> log -1"
            echo "  2. Run tests: cd ../<worktree> && npm test"
            echo "  3. Merge all: $SCRIPT_DIR/merge.sh"
            echo "  4. Or merge with cleanup: $SCRIPT_DIR/merge.sh --cleanup"
            echo ""
            echo "Or use /cpt:done to merge interactively."
        fi

        exit 0
    fi

    sleep "$POLL_INTERVAL"
done
