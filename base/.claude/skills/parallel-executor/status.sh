#!/bin/bash
# Check status of parallel Claude agents
# Usage: status.sh

PIDS_FILE="../.parallel-pids"
LOGS_DIR="../logs"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "                 PARALLEL AGENT STATUS"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [[ ! -f "$PIDS_FILE" ]]; then
    echo "No parallel agents running (no PID file found)"
    exit 0
fi

running=0
completed=0
failed=0

printf "%-25s %-10s %-15s %s\n" "TASK" "PID" "STATUS" "LAST OUTPUT"
echo "─────────────────────────────────────────────────────────────"

while IFS=: read -r pid name; do
    logfile="${LOGS_DIR}/${name}.log"
    last_line=""

    # Get last meaningful line from log
    if [[ -f "$logfile" ]]; then
        last_line=$(tail -1 "$logfile" 2>/dev/null | cut -c1-30)
    fi

    # Check if process is running
    if kill -0 "$pid" 2>/dev/null; then
        status="${YELLOW}RUNNING${NC}"
        ((running++))
    elif grep -q "TASK_COMPLETE" "$logfile" 2>/dev/null; then
        status="${GREEN}COMPLETE${NC}"
        ((completed++))
    elif grep -qi "error\|failed\|exception" "$logfile" 2>/dev/null; then
        status="${RED}FAILED${NC}"
        ((failed++))
    else
        status="${BLUE}STOPPED${NC}"
        ((completed++))
    fi

    printf "%-25s %-10s ${status}%-15s${NC} %s\n" "$name" "$pid" "" "$last_line"

done < "$PIDS_FILE"

echo ""
echo "─────────────────────────────────────────────────────────────"
echo -e "Summary: ${GREEN}$completed complete${NC} | ${YELLOW}$running running${NC} | ${RED}$failed failed${NC}"
echo ""

if [[ $running -gt 0 ]]; then
    echo "Still running. Check again with: $(basename $0)"
    echo "Or wait with: wait \$(cut -d: -f1 $PIDS_FILE)"
elif [[ $failed -gt 0 ]]; then
    echo "Some tasks failed. Check logs in $LOGS_DIR/"
else
    echo "All tasks complete! Run merge.sh to merge to main."
fi
echo ""
