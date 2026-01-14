
## BMAD Integration

### BMAD Workflow

I follow the BMAD Method phases:
1. **Analysis** - `/product-brief` for discovery
2. **Planning** - `/prd` or `/tech-spec` for requirements
3. **Solutioning** - `/architecture` for design
4. **Implementation** - `/dev-story` for task breakdown

### Auto-Parallel After /dev-story

When `/dev-story` completes and generates a story file:

1. **Parse** the story for implementation tasks
2. **Identify** parallel-eligible tasks (marked `[P]` or independent)
3. **If 3+ parallel tasks found**, offer automatic execution:

   ```
   I found 5 parallel tasks in this story:
   - Task 1: Set up authentication [P]
   - Task 2: Create user API [P]
   - Task 3: Build login UI [P]
   - Task 4: Implement dashboard [P]
   - Task 5: Integration tests [depends: 1,2,3,4]

   Would you like me to spawn parallel agents for tasks 1-4?
   ```

4. **On confirmation**, execute:
   ```bash
   .claude/skills/bmad-parallel/spawn-story.sh .bmad/stories/current.md
   ```

### BMAD Story Locations

I look for stories in:
- `.bmad/stories/*.md`
- `.bmad/current-story.md`
- `docs/stories/*.md`

### Task Detection Patterns

I recognize these as parallel tasks:
- `- [ ] Task description [P]`
- `- [ ] Task description (parallel)`
- Tasks with no `[depends:]` marker
- Tasks touching different file paths

I recognize these as sequential:
- `- [ ] Task [depends: 1,2]`
- `- [ ] Task (after: auth)`
- Tasks modifying same files
- Database migrations
- Integration tests

### BMAD Agent Prompts

When spawning agents for BMAD stories, I include:
```
You are implementing a task from a BMAD story.

Story: {story_file}
Task: {task_description}

Context:
- PRD: .bmad/prd.md (if exists)
- Architecture: .bmad/architecture.md (if exists)
- Tech Spec: .bmad/tech-spec.md (if exists)

Follow BMAD conventions:
1. Keep commits atomic and descriptive
2. Update story task status when complete
3. Document any deviations from spec
4. Output 'TASK_COMPLETE' when finished
```

### Post-Completion

After all parallel tasks complete:
1. Run `/dev-story` status check
2. Execute sequential/dependent tasks
3. Run integration tests
4. Merge all branches to main
5. Update story status to complete
