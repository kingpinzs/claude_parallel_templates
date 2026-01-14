---
description: Execute BMAD story tasks in parallel
arguments:
  - name: story_file
    description: Path to BMAD story file (default: auto-detect)
    required: false
---

Parse a BMAD story file and spawn parallel agents for eligible tasks.

## Story Detection

If no file provided, search in order:
1. `.bmad/stories/current-story.md`
2. `.bmad/current-story.md`
3. Most recently modified `.bmad/stories/*.md`

## Parsing

Extract tasks from the story's Implementation section:

```markdown
## Implementation Tasks

- [ ] Task 1: Description [P]
- [ ] Task 2: Description [P]
- [ ] Task 3: Description [depends: 1,2]
```

## Execution

1. **Read** the story file
2. **Parse** implementation tasks
3. **Categorize**:
   - Parallel: Has `[P]` or no dependencies
   - Sequential: Has `[depends:]` or shared resources
4. **Validate**: At least 2 parallel tasks
5. **Present** execution plan to user
6. **On approval**, spawn agents:
   ```bash
   .claude/skills/bmad-parallel/spawn-story.sh "$STORY_FILE"
   ```

## Agent Context

Each spawned agent receives:
- The specific task to implement
- Path to story file
- Paths to PRD, architecture, tech-spec if they exist
- Project's CLAUDE.md conventions

## Output

```
BMAD Story: .bmad/stories/user-auth.md

Parallel Tasks (spawning):
  ✓ auth-setup      → ../project-auth-setup
  ✓ user-api        → ../project-user-api
  ✓ login-ui        → ../project-login-ui

Sequential Tasks (queued):
  ⏳ integration-tests [after: auth-setup, user-api, login-ui]

Monitor: tail -f ../logs/*.log
Status:  .claude/skills/parallel-executor/status.sh
```

## Post-Execution

After parallel tasks complete:
1. Run `/bmad:parallel-story --continue` to execute sequential tasks
2. Or manually run `/worktree:done` for each
