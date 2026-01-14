
## Spec Kit Integration

### Spec-Driven Workflow

I follow the Spec Kit methodology:
1. **Specify** - `/specify` to create feature specification
2. **Plan** - `/plan` to create implementation plan
3. **Tasks** - `/tasks` to break down into executable tasks
4. **Implement** - `/implement` or parallel execution

### Spec Kit File Locations

| File | Purpose |
|------|---------|
| `.spec/spec.md` | Feature specification |
| `.spec/plan.md` | Implementation plan |
| `.spec/tasks.md` | Task breakdown |
| `.spec/design.md` | Design decisions |

### Auto-Parallel After /tasks

When `/tasks` completes and generates `.spec/tasks.md`:

1. **Parse** the tasks file for implementation items
2. **Identify** parallel-eligible tasks (marked `[P]` or independent)
3. **If 3+ parallel tasks found**, offer automatic execution:

   ```
   I found 4 parallel tasks in the spec:
   - Task 1: Create database models [P]
   - Task 2: Implement API endpoints [P]
   - Task 3: Build React components [P]
   - Task 4: E2E tests [depends: 1,2,3]

   Would you like me to spawn parallel agents for tasks 1-3?
   ```

4. **On confirmation**, execute:
   ```bash
   .claude/skills/spec-parallel/spawn-tasks.sh .spec/tasks.md
   ```

### Task Detection Patterns

I recognize these as parallel tasks:
- `- [ ] Task description [P]`
- `- [ ] Task description (parallel)`
- `### Task N [P]` headers
- Tasks with no dependency annotations

I recognize these as sequential:
- `- [ ] Task [depends: 1,2]`
- `- [ ] Task (requires: api)`
- `### Task N [sequential]`
- Tasks marked "after" or "needs"

### Spec Context for Agents

Each spawned agent receives:
```
You are implementing a task from a Spec Kit project.

## Your Task
{task_description}

## Specification
{spec_content}

## Implementation Plan
{plan_content}

## Design Decisions
{design_content}

Instructions:
1. Follow the specification exactly
2. Adhere to the implementation plan
3. Reference design decisions for ambiguities
4. Write tests alongside implementation
5. Commit with message: "feat(spec): {task_summary}"
6. Output 'TASK_COMPLETE' when finished

Begin implementation.
```

### Post-Completion

After all parallel tasks complete:
1. Run `.claude/skills/parallel-executor/status.sh`
2. Execute any sequential/dependent tasks
3. Run `/implement --validate` to verify against spec
4. Merge all branches to main
5. Run full test suite
