#!/bin/bash
# Persistent Plan Management for Cross-Session Continuity
# This manifest is stored IN git for cross-machine persistence
#
# Usage:
#   source plan.sh
#   plan_init "Build authentication system" "oauth,password-reset,2fa"
#   plan_add_task "oauth" "Implement OAuth 2.0 client" "src/auth/"
#   plan_set_task_status "oauth" "in_progress" "feature/oauth"
#   plan_get_pending_tasks
#   plan_status

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLAN_FILE=".claude/parallel-plan.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Check for jq
_check_jq() {
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}[plan]${NC} jq is required. Install with: apt install jq" >&2
        return 1
    fi
}

# Generate unique plan ID
_generate_plan_id() {
    echo "plan_$(date +%Y%m%d_%H%M%S)_$(head -c 4 /dev/urandom | xxd -p)"
}

# Initialize a new plan
# Args: $1=goal, $2=comma-separated task IDs (optional)
plan_init() {
    _check_jq || return 1

    local goal="$1"
    local task_ids="$2"
    local plan_id=$(_generate_plan_id)
    local created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Create .claude directory if needed
    mkdir -p "$(dirname "$PLAN_FILE")"

    # Check if plan already exists
    if [[ -f "$PLAN_FILE" ]]; then
        local existing_status=$(jq -r '.status' "$PLAN_FILE" 2>/dev/null)
        if [[ "$existing_status" == "in_progress" ]]; then
            echo -e "${YELLOW}[plan]${NC} Active plan already exists. Use plan_status to view or plan_archive to archive." >&2
            return 1
        fi
    fi

    # Create initial plan structure
    cat > "$PLAN_FILE" << EOF
{
  "version": "1.0",
  "plan_id": "$plan_id",
  "goal": "$goal",
  "status": "planning",
  "created_at": "$created_at",
  "updated_at": "$created_at",
  "tasks": [],
  "history": []
}
EOF

    # Add initial tasks if provided
    if [[ -n "$task_ids" ]]; then
        IFS=',' read -ra ids <<< "$task_ids"
        for id in "${ids[@]}"; do
            id=$(echo "$id" | xargs)  # trim whitespace
            plan_add_task "$id" "" ""
        done
    fi

    echo -e "${GREEN}[plan]${NC} Created plan: $plan_id"
    echo -e "${GREEN}[plan]${NC} Goal: $goal"
}

# Add a task to the plan
# Args: $1=task_id, $2=description, $3=scope (files/directories), $4=depends_on (comma-separated)
plan_add_task() {
    _check_jq || return 1

    local task_id="$1"
    local description="${2:-}"
    local scope="${3:-}"
    local depends_on="${4:-}"

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo -e "${RED}[plan]${NC} No plan exists. Run plan_init first." >&2
        return 1
    fi

    # Check if task already exists
    local existing=$(jq -r --arg id "$task_id" '.tasks[] | select(.id == $id) | .id' "$PLAN_FILE")
    if [[ -n "$existing" ]]; then
        echo -e "${YELLOW}[plan]${NC} Task '$task_id' already exists." >&2
        return 1
    fi

    local created_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Build depends_on array
    local deps_json="[]"
    if [[ -n "$depends_on" ]]; then
        deps_json=$(echo "$depends_on" | tr ',' '\n' | xargs -I{} echo '"{}"' | jq -s '.')
    fi

    # Add task to plan
    local temp_file=$(mktemp)
    jq --arg id "$task_id" \
       --arg desc "$description" \
       --arg scope "$scope" \
       --argjson deps "$deps_json" \
       --arg created "$created_at" \
       '.tasks += [{
         "id": $id,
         "description": $desc,
         "scope": $scope,
         "status": "pending",
         "depends_on": $deps,
         "branch": null,
         "worktree": null,
         "created_at": $created,
         "started_at": null,
         "merged_at": null,
         "commits": []
       }] | .updated_at = $created' \
       "$PLAN_FILE" > "$temp_file" && mv "$temp_file" "$PLAN_FILE"

    echo -e "${GREEN}[plan]${NC} Added task: $task_id"
}

# Update task status
# Args: $1=task_id, $2=new_status (pending|in_progress|completed|merged|failed), $3=branch (optional)
plan_set_task_status() {
    _check_jq || return 1

    local task_id="$1"
    local new_status="$2"
    local branch="${3:-}"
    local worktree="${4:-}"

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo -e "${RED}[plan]${NC} No plan exists." >&2
        return 1
    fi

    local updated_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp_file=$(mktemp)

    # Build update based on status
    case $new_status in
        "in_progress")
            jq --arg id "$task_id" \
               --arg new_status "$new_status" \
               --arg branch "$branch" \
               --arg worktree "$worktree" \
               --arg updated "$updated_at" \
               --arg started "$updated_at" \
               '(.tasks[] | select(.id == $id)) |= (
                 .status = $new_status |
                 .branch = $branch |
                 .worktree = $worktree |
                 .started_at = $started
               ) | .updated_at = $updated | .status = "in_progress"' \
               "$PLAN_FILE" > "$temp_file" && mv "$temp_file" "$PLAN_FILE"
            ;;
        "merged")
            jq --arg id "$task_id" \
               --arg new_status "$new_status" \
               --arg updated "$updated_at" \
               --arg merged "$updated_at" \
               '(.tasks[] | select(.id == $id)) |= (
                 .status = $new_status |
                 .merged_at = $merged |
                 .worktree = null
               ) | .updated_at = $updated' \
               "$PLAN_FILE" > "$temp_file" && mv "$temp_file" "$PLAN_FILE"

            # Add to history
            _add_history_entry "$task_id" "merged"

            # Check if all tasks are merged
            _check_plan_completion
            ;;
        *)
            jq --arg id "$task_id" \
               --arg new_status "$new_status" \
               --arg updated "$updated_at" \
               '(.tasks[] | select(.id == $id)).status = $new_status | .updated_at = $updated' \
               "$PLAN_FILE" > "$temp_file" && mv "$temp_file" "$PLAN_FILE"
            ;;
    esac

    echo -e "${GREEN}[plan]${NC} Task '$task_id' status: $new_status"
}

# Add a commit to task history
# Args: $1=task_id, $2=commit_hash, $3=message
plan_add_commit() {
    _check_jq || return 1

    local task_id="$1"
    local commit_hash="$2"
    local message="$3"

    if [[ ! -f "$PLAN_FILE" ]]; then
        return 0  # Silently skip if no plan
    fi

    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp_file=$(mktemp)

    jq --arg id "$task_id" \
       --arg hash "$commit_hash" \
       --arg msg "$message" \
       --arg ts "$timestamp" \
       '(.tasks[] | select(.id == $id)).commits += [{
         "hash": $hash,
         "message": $msg,
         "timestamp": $ts
       }]' \
       "$PLAN_FILE" > "$temp_file" && mv "$temp_file" "$PLAN_FILE"
}

# Add history entry
_add_history_entry() {
    local task_id="$1"
    local action="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local temp_file=$(mktemp)

    jq --arg id "$task_id" \
       --arg action "$action" \
       --arg ts "$timestamp" \
       '.history += [{
         "task_id": $id,
         "action": $action,
         "timestamp": $ts
       }]' \
       "$PLAN_FILE" > "$temp_file" && mv "$temp_file" "$PLAN_FILE"
}

# Check if all tasks are complete
_check_plan_completion() {
    local pending=$(jq '[.tasks[] | select(.status != "merged")] | length' "$PLAN_FILE")

    if [[ "$pending" -eq 0 ]]; then
        local temp_file=$(mktemp)
        local completed_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        jq --arg status "completed" \
           --arg completed "$completed_at" \
           '.status = $status | .completed_at = $completed' \
           "$PLAN_FILE" > "$temp_file" && mv "$temp_file" "$PLAN_FILE"
        echo -e "${GREEN}[plan]${NC} All tasks merged! Plan completed."
    fi
}

# Get pending tasks (returns JSON array)
plan_get_pending_tasks() {
    _check_jq || return 1

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "[]"
        return 0
    fi

    jq '[.tasks[] | select(.status == "pending")]' "$PLAN_FILE"
}

# Get tasks ready to start (pending with no unmet dependencies)
plan_get_ready_tasks() {
    _check_jq || return 1

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "[]"
        return 0
    fi

    # Get merged task IDs
    local merged_ids=$(jq -r '[.tasks[] | select(.status == "merged") | .id]' "$PLAN_FILE")

    # Get pending tasks where all dependencies are merged
    jq --argjson merged "$merged_ids" \
       '[.tasks[] | select(
         .status == "pending" and
         ((.depends_on | length) == 0 or (.depends_on | all(. as $dep | $merged | index($dep))))
       )]' "$PLAN_FILE"
}

# Get in-progress tasks
plan_get_active_tasks() {
    _check_jq || return 1

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "[]"
        return 0
    fi

    jq '[.tasks[] | select(.status == "in_progress")]' "$PLAN_FILE"
}

# Get task by ID
plan_get_task() {
    _check_jq || return 1

    local task_id="$1"

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "null"
        return 0
    fi

    jq --arg id "$task_id" '.tasks[] | select(.id == $id)' "$PLAN_FILE"
}

# Check if plan exists and is active
plan_exists() {
    if [[ ! -f "$PLAN_FILE" ]]; then
        return 1
    fi

    local status=$(jq -r '.status' "$PLAN_FILE" 2>/dev/null)
    [[ "$status" == "planning" || "$status" == "in_progress" ]]
}

# Get plan status summary
plan_status() {
    _check_jq || return 1

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo -e "${YELLOW}[plan]${NC} No plan exists."
        return 0
    fi

    local plan_id=$(jq -r '.plan_id' "$PLAN_FILE")
    local goal=$(jq -r '.goal' "$PLAN_FILE")
    local plan_status=$(jq -r '.status' "$PLAN_FILE")
    local created=$(jq -r '.created_at' "$PLAN_FILE" | cut -d'T' -f1)

    local total=$(jq '.tasks | length' "$PLAN_FILE")
    local pending=$(jq '[.tasks[] | select(.status == "pending")] | length' "$PLAN_FILE")
    local in_progress=$(jq '[.tasks[] | select(.status == "in_progress")] | length' "$PLAN_FILE")
    local merged=$(jq '[.tasks[] | select(.status == "merged")] | length' "$PLAN_FILE")
    local failed=$(jq '[.tasks[] | select(.status == "failed")] | length' "$PLAN_FILE")

    echo ""
    echo "═══════════════════════════════════════════════════════════"
    echo "                    PLAN STATUS"
    echo "═══════════════════════════════════════════════════════════"
    echo ""
    echo -e "Plan ID:  ${CYAN}$plan_id${NC}"
    echo -e "Goal:     $goal"
    echo -e "Status:   $plan_status"
    echo -e "Created:  $created"
    echo ""
    echo "─────────────────────────────────────────────────────────────"
    printf "%-25s %-12s %-15s %s\n" "TASK" "STATUS" "BRANCH" "DEPENDS ON"
    echo "─────────────────────────────────────────────────────────────"

    jq -r '.tasks[] | "\(.id)|\(.status)|\(.branch // "-")|\(.depends_on | join(","))"' "$PLAN_FILE" | \
    while IFS='|' read -r id task_status branch deps; do
        case $task_status in
            "pending")   status_color="${YELLOW}pending${NC}" ;;
            "in_progress") status_color="${BLUE}active${NC}" ;;
            "merged")    status_color="${GREEN}merged${NC}" ;;
            "failed")    status_color="${RED}failed${NC}" ;;
            *)           status_color="$task_status" ;;
        esac
        printf "%-25s %-20b %-15s %s\n" "$id" "$status_color" "$branch" "${deps:-none}"
    done

    echo ""
    echo "─────────────────────────────────────────────────────────────"
    echo -e "Summary: ${GREEN}$merged merged${NC} | ${BLUE}$in_progress active${NC} | ${YELLOW}$pending pending${NC} | ${RED}$failed failed${NC}"
    echo -e "Progress: $merged / $total tasks complete"
    echo ""

    if [[ $pending -gt 0 ]]; then
        local ready=$(plan_get_ready_tasks | jq 'length')
        echo -e "${CYAN}$ready task(s) ready to start${NC} (dependencies met)"
        echo "Run /cpt:continue to spawn agents for ready tasks"
    elif [[ $in_progress -gt 0 ]]; then
        echo "Agents are working. Check status with /cpt:list"
    else
        echo -e "${GREEN}All tasks complete!${NC}"
    fi
    echo ""
}

# Archive current plan (for starting fresh)
plan_archive() {
    _check_jq || return 1

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo -e "${YELLOW}[plan]${NC} No plan to archive."
        return 0
    fi

    local plan_id=$(jq -r '.plan_id' "$PLAN_FILE")
    local archive_dir=".claude/archived-plans"
    mkdir -p "$archive_dir"

    local archive_file="$archive_dir/${plan_id}.json"
    mv "$PLAN_FILE" "$archive_file"

    echo -e "${GREEN}[plan]${NC} Archived plan to: $archive_file"
}

# Export plan as markdown (for documentation)
plan_export_md() {
    _check_jq || return 1

    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "No plan exists."
        return 0
    fi

    local goal=$(jq -r '.goal' "$PLAN_FILE")
    local status=$(jq -r '.status' "$PLAN_FILE")
    local created=$(jq -r '.created_at' "$PLAN_FILE")

    echo "# Project Plan"
    echo ""
    echo "**Goal:** $goal"
    echo "**Status:** $status"
    echo "**Created:** $created"
    echo ""
    echo "## Tasks"
    echo ""

    jq -r '.tasks[] | "- [\(if .status == "merged" then "x" else " " end)] **\(.id)**: \(.description // "No description") (\(.status))"' "$PLAN_FILE"

    echo ""
    echo "## History"
    echo ""
    jq -r '.history[] | "- \(.timestamp | split("T")[0]): \(.task_id) - \(.action)"' "$PLAN_FILE"
}

# If script is run directly, show usage
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "init")
            shift
            plan_init "$@"
            ;;
        "add")
            shift
            plan_add_task "$@"
            ;;
        "status")
            plan_status
            ;;
        "pending")
            plan_get_pending_tasks
            ;;
        "ready")
            plan_get_ready_tasks
            ;;
        "active")
            plan_get_active_tasks
            ;;
        "archive")
            plan_archive
            ;;
        "export")
            plan_export_md
            ;;
        *)
            echo "Usage: plan.sh <command> [args]"
            echo ""
            echo "Commands:"
            echo "  init <goal> [task_ids]  - Create new plan"
            echo "  add <id> [desc] [scope] - Add task to plan"
            echo "  status                  - Show plan status"
            echo "  pending                 - List pending tasks (JSON)"
            echo "  ready                   - List ready tasks (JSON)"
            echo "  active                  - List active tasks (JSON)"
            echo "  archive                 - Archive current plan"
            echo "  export                  - Export plan as markdown"
            ;;
    esac
fi
