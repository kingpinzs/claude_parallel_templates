# Claude Code Parallel Development - BMAD Template

BMAD Method v6 integrated with automatic parallel execution.

## Quick Start

```bash
# 1. Copy base template first
cp -r /path/to/base/.claude /your/project/
cp /path/to/base/CLAUDE.md /your/project/

# 2. Copy BMAD additions (merges with base)
cp -r /path/to/bmad/.claude/* /your/project/.claude/
cat /path/to/bmad/CLAUDE.md >> /your/project/CLAUDE.md

# 3. Install BMAD skills (optional - for full BMAD)
git clone https://github.com/aj-geddes/claude-code-bmad-skills /tmp/bmad
cd /tmp/bmad && ./install.sh

# 4. Set up bare repo pattern
# (see base template README)

# 5. Start Claude
claude
```

## What's Added (on top of base)

```
.claude/
├── commands/
│   └── bmad/
│       └── parallel-story.md   # /bmad:parallel-story
├── skills/
│   └── bmad-parallel/
│       ├── SKILL.md            # Auto-parallel after /dev-story
│       └── parse-story.sh      # Extracts tasks from BMAD stories
```

## BMAD + Parallel Workflow

```
/workflow-init           # Initialize BMAD
/product-brief           # Discovery phase
/prd                     # Requirements
/architecture            # Design
/dev-story               # Story breakdown
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

After `/dev-story` completes, if 3+ tasks are detected:
- Claude automatically offers parallel execution
- Confirm to spawn agents
- Monitor with provided commands
- Merge when complete

### Manual

```bash
# After /dev-story creates story file
/bmad:parallel-story .bmad/stories/current-story.md
```

## Story Format Expected

BMAD stories should have tasks formatted as:

```markdown
## Implementation Tasks

- [ ] Task 1: Set up authentication [P]
- [ ] Task 2: Create user API [P]
- [ ] Task 3: Build login UI [P]
- [ ] Task 4: Integration tests [depends: 1,2,3]
```

The `[P]` marker indicates parallel-eligible tasks.

## Full BMAD Commands (if installed)

| Command | Phase | Description |
|---------|-------|-------------|
| /workflow-init | Setup | Initialize BMAD |
| /product-brief | Analysis | Product discovery |
| /prd | Planning | Requirements doc |
| /tech-spec | Planning | Technical spec |
| /architecture | Solutioning | System design |
| /dev-story | Implementation | Story breakdown |
| /bmad:parallel-story | Implementation | Parallel spawn |

## Customization

Edit `CLAUDE.md` BMAD section to adjust:
- Minimum tasks for auto-parallel (default: 3)
- Story file locations
- Task parsing patterns
