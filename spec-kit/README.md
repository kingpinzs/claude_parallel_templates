# Claude Code Parallel Development - Spec Kit Template

GitHub Spec Kit integrated with automatic parallel execution.

## Quick Start

```bash
# 1. Copy base template first
cp -r /path/to/base/.claude /your/project/
cp /path/to/base/CLAUDE.md /your/project/

# 2. Copy Spec Kit additions (merges with base)
cp -r /path/to/spec-kit/.claude/* /your/project/.claude/
cat /path/to/spec-kit/CLAUDE.md >> /your/project/CLAUDE.md

# 3. Install Spec Kit
npx speckit init . --ai claude

# 4. Set up bare repo pattern
# (see base template README)

# 5. Start Claude
claude
```

## What's Added (on top of base)

```
.claude/
├── commands/
│   └── spec/
│       └── parallel-tasks.md   # /spec:parallel-tasks
├── skills/
│   └── spec-parallel/
│       ├── SKILL.md            # Auto-parallel after /tasks
│       └── spawn-tasks.sh      # Spawns from .spec/tasks.md
```

## Spec Kit + Parallel Workflow

```
/specify "feature"       # Generate specification
/plan                    # Create implementation plan
/tasks                   # Break down into tasks
                         ↓
              ┌──────────────────────┐
              │ AUTOMATIC DETECTION  │
              │ Parallel tasks found │
              └──────────────────────┘
                         ↓
         Worktree per task + Claude -p spawn
                         ↓
              Monitor → Merge → Cleanup
```

## Usage

### Automatic (Recommended)

After `/tasks` completes, if parallel-eligible tasks are detected:
- Claude automatically offers parallel execution
- Confirm to spawn agents
- Monitor with provided commands
- Merge when complete

### Manual

```bash
# After /tasks creates tasks.md
/spec:parallel-tasks .spec/tasks.md
```

## Task Format Expected

Spec Kit tasks should be formatted as:

```markdown
## Tasks

- [ ] Task 1: Set up database schema [P]
- [ ] Task 2: Create REST API [P]
- [ ] Task 3: Build frontend components [P]
- [ ] Task 4: Write E2E tests [depends: 1,2,3]
```

The `[P]` marker indicates parallel-eligible tasks.

## Spec Kit Files

| File | Purpose |
|------|---------|
| `.spec/spec.md` | Feature specification |
| `.spec/plan.md` | Implementation plan |
| `.spec/tasks.md` | Task breakdown |
| `.spec/design.md` | Design decisions |

## Full Spec Kit Commands

| Command | Description |
|---------|-------------|
| /specify | Generate specification from prompt |
| /plan | Create implementation plan |
| /tasks | Break down into executable tasks |
| /implement | Execute implementation |
| /spec:parallel-tasks | Parallel spawn (this template) |

## Customization

Edit `CLAUDE.md` Spec Kit section to adjust:
- Minimum tasks for auto-parallel (default: 3)
- Spec file locations
- Task parsing patterns
