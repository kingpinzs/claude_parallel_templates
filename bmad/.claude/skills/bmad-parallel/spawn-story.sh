#!/bin/bash
# BMAD Story Parallel Spawner
# Usage: spawn-story.sh [story-file]

set -e

# Find story file
if [[ -n "$1" ]] && [[ -f "$1" ]]; then
    STORY_FILE="$1"
elif [[ -f ".bmad/stories/current-story.md" ]]; then
    STORY_FILE=".bmad/stories/current-story.md"
elif [[ -f ".bmad/current-story.md" ]]; then
    STORY_FILE=".bmad/current-story.md"
else
    # Find most recent story
    STORY_FILE=$(ls -t .bmad/stories/*.md 2>/dev/null | head -1)
fi

[[ -z "$STORY_FILE" ]] && { echo "No story file found"; exit 1; }
[[ ! -f "$STORY_FILE" ]] && { echo "Story file not found: $STORY_FILE"; exit 1; }

PROJECT=$(basename $(pwd))
LOGS_DIR="../logs"
PIDS_FILE="../.parallel-pids"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}[bmad]${NC} $1"; }

# Gather BMAD context
CONTEXT=""
[[ -f ".bmad/prd.md" ]] && CONTEXT="$CONTEXT\n\nPRD Summary:\n$(head -50 .bmad/prd.md)"
[[ -f ".bmad/architecture.md" ]] && CONTEXT="$CONTEXT\n\nArchitecture Summary:\n$(head -50 .bmad/architecture.md)"
[[ -f ".bmad/tech-spec.md" ]] && CONTEXT="$CONTEXT\n\nTech Spec Summary:\n$(head -50 .bmad/tech-spec.md)"

# Extract parallel tasks from story
log "Parsing story: $STORY_FILE"

# Extract tasks marked with [P] or (P)
TASKS=$(grep -E '^\s*-\s*\[\s*\].*\[P\]|^\s*-\s*\[\s*\].*\(P\)' "$STORY_FILE" | \
        sed 's/^[^]]*\]//' | \
        sed 's/\[P\]//' | \
        sed 's/(P)//' | \
        sed 's/^\s*//' | \
        sed 's/\s*$//')

if [[ -z "$TASKS" ]]; then
    log "No parallel tasks found in story"
    log "Mark tasks with [P] to enable parallel execution"
    exit 0
fi

TASK_COUNT=$(echo "$TASKS" | wc -l)
log "Found $TASK_COUNT parallel tasks"

mkdir -p "$LOGS_DIR"
> "$PIDS_FILE"

echo ""
log "Spawning BMAD story tasks..."
echo ""

# Read story content for context
STORY_CONTENT=$(cat "$STORY_FILE")

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

    # Spawn Claude with BMAD context
    (
        cd "$worktree"

        # Install dependencies
        [[ -f "package.json" ]] && npm install --silent 2>/dev/null || true

        # Run Claude with full BMAD context
        claude -p "You are a BMAD implementation agent.

## Your Task
$task

## Story Context
$STORY_CONTENT

## Project Context
$CONTEXT

## Instructions
1. Implement ONLY the assigned task above
2. Follow existing code patterns in this repository
3. Write tests for any new functionality
4. Keep commits atomic with message format: feat(story): description
5. Do not modify unrelated files
6. Output 'TASK_COMPLETE' when finished

Begin implementation now." \
            --dangerously-skip-permissions \
            2>&1 | tee "$logfile"

        echo "TASK_COMPLETE: $name" >> "$logfile"
    ) &

    pid=$!
    echo "$pid:$name" >> "$PIDS_FILE"
    log "  PID: $pid → $worktree"
done

echo ""
log "All BMAD agents spawned!"
echo ""
echo "Story: $STORY_FILE"
echo ""
echo "Commands:"
echo "  tail -f $LOGS_DIR/*.log                    # Watch logs"
echo "  .claude/skills/parallel-executor/status.sh # Check status"
echo "  .claude/skills/parallel-executor/merge.sh  # Merge when done"
