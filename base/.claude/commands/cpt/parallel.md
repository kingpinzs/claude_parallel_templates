---
description: Spawn multiple parallel Claude sessions from a task list
arguments:
  - name: tasks
    description: Comma-separated task descriptions OR path to tasks file
    required: true
---

Create multiple worktrees and spawn parallel Claude sessions for each task.

## Input Parsing

**Option 1: Comma-separated tasks**
```
/cpt:parallel "add auth, create api, build ui"
```

**Option 2: Tasks file**
```
/cpt:parallel tasks.md
```

Tasks file format:
```markdown
- [ ] Add authentication [P]
- [ ] Create API endpoints [P]
- [ ] Build dashboard UI [P]
- [ ] Integration tests [depends: 1,2,3]
```

## Execution Steps

1. **Parse input** into task list
2. **Filter** for parallel-eligible tasks (marked [P] or no dependencies)
3. **Validate** count (max 10 parallel)
4. **Create logs directory:**
   ```bash
   mkdir -p ../logs
   ```

5. **For each parallel task:**
   ```bash
   # Generate safe name from task description
   NAME=$(echo "$TASK" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | cut -c1-25)
   PROJECT=$(basename $(pwd))

   # Create worktree
   git worktree add "../${PROJECT}-${NAME}" -b "feature/${NAME}" main

   # Spawn agent
   (
     cd "../${PROJECT}-${NAME}"
     npm install 2>/dev/null || yarn 2>/dev/null || true
     claude -p "Implement: $TASK

Follow project conventions in CLAUDE.md.
Commit when complete with descriptive message." \
       --dangerously-skip-permissions \
       > "../logs/${NAME}.log" 2>&1
   ) &

   echo "$!" >> "../.parallel-pids"
   echo "Spawned: $NAME (PID: $!)"
   ```

6. **Output monitoring script:**
   ```bash
   echo "
   # Monitor all agents
   tail -f ../logs/*.log

   # Check which are still running
   for pid in \$(cat ../.parallel-pids); do
     kill -0 \$pid 2>/dev/null && echo \"\$pid: RUNNING\" || echo \"\$pid: DONE\"
   done

   # Wait for all to complete
   wait \$(cat ../.parallel-pids)
   echo 'All agents complete'
   "
   ```

## Output Summary

| Task | Worktree | Branch | PID | Log |
|------|----------|--------|-----|-----|
| Add auth | ../proj-add-auth | feature/add-auth | 12345 | ../logs/add-auth.log |
| Create API | ../proj-create-api | feature/create-api | 12346 | ../logs/create-api.log |

## After Completion

Run `/cpt:list` to see status, then `/cpt:done <name>` for each, or:

```bash
# Merge all completed worktrees
for wt in ../$(basename $(pwd))-*; do
  cd ../main && git merge $(git -C "$wt" branch --show-current) --no-edit
  git worktree remove "$wt"
done
```

## Limits

- Maximum 10 parallel tasks
- Sequential tasks (with dependencies) are queued, not spawned
- Each agent gets ~200k token context
