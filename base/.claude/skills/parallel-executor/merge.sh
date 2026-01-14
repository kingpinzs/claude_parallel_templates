#!/bin/bash
# Merge all parallel worktrees to main
# Usage: merge.sh [--cleanup]

set -e

PROJECT=$(basename $(pwd))
PIDS_FILE="../.parallel-pids"
CLEANUP=false

[[ "$1" == "--cleanup" ]] && CLEANUP=true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[merge]${NC} $1"; }
warn() { echo -e "${YELLOW}[merge]${NC} $1"; }
error() { echo -e "${RED}[merge]${NC} $1"; }

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                 MERGING PARALLEL WORKTREES"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Check for running processes
if [[ -f "$PIDS_FILE" ]]; then
    while IFS=: read -r pid name; do
        if kill -0 "$pid" 2>/dev/null; then
            error "Agent still running: $name (PID: $pid)"
            echo "Wait for completion or kill with: kill $pid"
            exit 1
        fi
    done < "$PIDS_FILE"
fi

# Find all project worktrees (excluding main)
WORKTREES=$(git worktree list --porcelain | grep "^worktree" | cut -d' ' -f2 | grep -v "/main$" | grep "/${PROJECT}-" || true)

if [[ -z "$WORKTREES" ]]; then
    log "No worktrees to merge"
    exit 0
fi

# Switch to main
log "Switching to main..."
cd ../main
git pull origin main 2>/dev/null || true

merged=0
failed=0
skipped=0

for wt in $WORKTREES; do
    name=$(basename "$wt")
    branch=$(git -C "$wt" branch --show-current 2>/dev/null || echo "unknown")

    echo ""
    log "Processing: $name ($branch)"

    # Check for uncommitted changes
    if [[ -n $(git -C "$wt" status --porcelain 2>/dev/null) ]]; then
        warn "  Uncommitted changes in $name - skipping"
        ((skipped++))
        continue
    fi

    # Try to merge
    if git merge "$branch" --no-edit 2>/dev/null; then
        log "  Merged successfully"
        ((merged++))

        if $CLEANUP; then
            log "  Cleaning up worktree..."
            cd ..
            git worktree remove "$wt" 2>/dev/null || warn "  Could not remove worktree"
            git branch -d "$branch" 2>/dev/null || warn "  Could not delete branch"
            cd main
        fi
    else
        error "  Merge conflict in $name"
        git merge --abort 2>/dev/null || true
        ((failed++))
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════"
echo -e "Results: ${GREEN}$merged merged${NC} | ${RED}$failed failed${NC} | ${YELLOW}$skipped skipped${NC}"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [[ $failed -gt 0 ]]; then
    echo "Some merges failed. Resolve conflicts manually:"
    echo "  cd <worktree> && git status"
    echo "  # fix conflicts"
    echo "  cd ../main && git merge <branch>"
elif [[ $skipped -gt 0 ]]; then
    echo "Some worktrees had uncommitted changes. Commit them first:"
    echo "  cd <worktree> && git add -A && git commit -m 'message'"
else
    log "All merges complete!"
    if ! $CLEANUP; then
        echo ""
        echo "Run with --cleanup to remove worktrees:"
        echo "  $(basename $0) --cleanup"
    fi
fi

# Cleanup PID file
if $CLEANUP && [[ $failed -eq 0 ]] && [[ $skipped -eq 0 ]]; then
    rm -f "$PIDS_FILE"
    rm -rf ../logs
    git worktree prune
    log "Cleanup complete"
fi
