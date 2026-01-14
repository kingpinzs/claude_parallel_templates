# Project Configuration

## Parallel Development Protocol

When working on features that can be parallelized, I follow this protocol:

### Detection Triggers

Automatically consider parallel execution when:
- Feature has 3+ independent components
- User mentions: "parallelize", "spawn", "fork", "parallel", "concurrent"
- Task list contains items marked with `[P]` or `(P)`
- Multiple unrelated files need changes simultaneously

### Parallel Execution Steps

1. **Decompose** the feature into independent tasks
2. **Present** task breakdown to user for approval
3. **Create worktrees** for each parallel task:
   ```bash
   git worktree add ../$PROJECT-$TASK -b feature/$TASK main
   ```
4. **Spawn headless Claude** in each worktree:
   ```bash
   (cd ../$PROJECT-$TASK && claude -p "$PROMPT" --dangerously-skip-permissions > ../logs/$TASK.log 2>&1) &
   ```
5. **Report** spawned tasks with monitoring commands
6. **On completion**, offer to merge results

### Task Independence Rules

Tasks are independent if they:
- Touch different files/directories
- Have no shared state dependencies
- Can be tested in isolation
- Don't modify shared configuration

Tasks are sequential if they:
- Modify the same files
- Have explicit `[depends: X]` markers
- Share database migrations
- Require output from another task

### Monitoring Commands

After spawning, I provide:
```bash
# Watch all logs
tail -f ../logs/*.log

# Check running processes
ps aux | grep "claude -p"

# Check completion
for f in ../logs/*.log; do
  grep -q "completed\|error\|failed" "$f" && echo "$f: DONE" || echo "$f: RUNNING"
done
```

### Merge Protocol

1. Wait for all tasks to complete
2. Run tests in each worktree
3. Merge to main in dependency order:
   ```bash
   cd ../main
   git pull origin main
   for branch in feature/*; do
     git merge $branch --no-edit
   done
   ```
4. Run final integration tests
5. Clean up worktrees:
   ```bash
   git worktree list | grep -v main | awk '{print $1}' | xargs -I {} git worktree remove {}
   git worktree prune
   ```

### Safety Rules

- Never spawn more than 10 parallel agents
- Always create worktrees (never parallel in same directory)
- Capture all output to log files
- Ask before merging if conflicts detected
- Clean up worktrees after successful merge

## Project-Specific Notes

<!-- Add your project-specific instructions here -->
