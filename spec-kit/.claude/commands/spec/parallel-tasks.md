---
description: Execute Spec Kit tasks in parallel
arguments:
  - name: tasks_file
    description: Path to tasks file (default: .spec/tasks.md)
    required: false
---

Parse Spec Kit tasks and spawn parallel agents for eligible tasks.

## Tasks Detection

If no file provided, look for:
1. `.spec/tasks.md`
2. `tasks.md`
3. `docs/tasks.md`

## Parsing

Extract tasks from the file:

```markdown
## Implementation Tasks

- [ ] Task 1: Database models [P]
- [ ] Task 2: API endpoints [P]
- [ ] Task 3: Frontend components [P]
- [ ] Task 4: Integration tests [depends: 1,2,3]
```

Or header format:
```markdown
### Task 1: Database Models [P]
Description of the task...

### Task 2: API Endpoints [P]
Description of the task...
```

## Execution

1. **Read** the tasks file
2. **Parse** task entries
3. **Load** spec context:
   - `.spec/spec.md` - Feature specification
   - `.spec/plan.md` - Implementation plan
   - `.spec/design.md` - Design decisions
4. **Categorize**:
   - Parallel: Has `[P]` or no dependencies
   - Sequential: Has `[depends:]` marker
5. **Present** execution plan to user
6. **On approval**, spawn agents:
   ```bash
   .claude/skills/spec-parallel/spawn-tasks.sh "$TASKS_FILE"
   ```

## Agent Context

Each spawned agent receives:
- The specific task description
- Full specification from `.spec/spec.md`
- Implementation plan from `.spec/plan.md`
- Design decisions from `.spec/design.md`
- Project's CLAUDE.md conventions

## Output

```
Spec Kit Tasks: .spec/tasks.md

Parallel Tasks (spawning):
  ✓ database-models  → ../project-database-models
  ✓ api-endpoints    → ../project-api-endpoints
  ✓ frontend-comps   → ../project-frontend-comps

Sequential Tasks (queued):
  ⏳ integration-tests [after: database-models, api-endpoints, frontend-comps]

Spec files loaded:
  ✓ .spec/spec.md
  ✓ .spec/plan.md
  ✓ .spec/design.md

Monitor: tail -f ../logs/*.log
Status:  .claude/skills/parallel-executor/status.sh
```

## Validation

After parallel tasks complete:
1. Run tests in each worktree
2. Verify implementation matches spec
3. Merge to main
4. Run full validation
