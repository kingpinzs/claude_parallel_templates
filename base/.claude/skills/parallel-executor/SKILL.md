---
name: parallel-executor
description: Automatically detect and execute parallel development tasks
triggers:
  - "parallelize"
  - "spawn agents"
  - "run in parallel"
  - "fork this"
  - "multiple tasks"
  - "work on issue #"
  - "fix the bugs"
  - "address the open issues"
  - "work on these issues"
  - tasks with "[P]" markers detected
---

# Parallel Executor Skill

I automatically orchestrate parallel Claude Code sessions when tasks can be executed concurrently.

## Key Principle

**Only spawn agents when there are truly independent tasks.** Single tasks or tightly coupled work stay in the current session. Spawning is not the default - it's an optimization for genuinely parallel work.

## When I Activate

- User explicitly requests parallel execution
- Task breakdown contains 2+ truly independent items
- File contains `[P]` or `(P)` parallel markers
- Multiple unrelated GitHub issues are being addressed

## Independence Criteria

**Tasks are INDEPENDENT (can spawn) if:**
- They touch completely different files/directories
- No shared state or dependencies between tasks
- Tasks can be tested in isolation
- Merging results won't cause conflicts
- Examples: OAuth auth + dark mode theme, API endpoints + CLI tool

**Tasks are COUPLED (stay in session) if:**
- They modify the same files
- One depends on the other's output
- They share state (database schema, config, API contracts)
- They're steps of the same feature
- Examples: Adding a feature + its tests, UI component + its state

## My Process

### 1. Task Analysis

I examine the work to identify:
- Independent tasks (can run in parallel)
- Dependent tasks (must wait for others)
- Shared resources (require coordination)

**Important:** I always ask for confirmation before spawning agents.

### 2. Dependency Graph

```
Task A [P] ──┐
Task B [P] ──┼──> Task E [depends: A,B,C]
Task C [P] ──┘
Task D [P] ────> Task F [depends: D]
```

### 3. Execution Plan

For parallel tasks, I use the spawn script:
```bash
.claude/skills/parallel-executor/spawn.sh "task1" "task2" "task3"
```

For sequential tasks, I queue them after dependencies complete.

### 4. Monitoring

I provide real-time status commands:
```bash
# Live logs
tail -f ../logs/*.log

# Process status
ps aux | grep "claude -p"

# Completion check
.claude/skills/parallel-executor/status.sh
```

### 5. Merge Coordination

When all parallel tasks complete:
1. Verify each worktree has clean commits
2. Run tests in each worktree
3. Merge to main in safe order
4. Clean up worktrees and branches

## Files

- `spawn.sh` - Creates worktrees and spawns agents
- `status.sh` - Checks agent completion status
- `merge.sh` - Merges all completed worktrees

## Limits

- Max 10 concurrent agents
- Each agent: 200k token context
- Timeout: 30 minutes per task (configurable)

## Error Handling

If an agent fails:
1. Capture error from log file
2. Report to user
3. Offer: retry, skip, or abort all
4. Never auto-merge failed tasks
