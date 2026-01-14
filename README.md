# Claude Code Parallel Development Templates

Drop-in templates for running parallel Claude Code sessions with git worktrees.

## Quick Install

### Using uv (recommended)

```bash
# Install the tool
uv tool install claude-parallel --from git+https://github.com/kingpinzs/claude_parallel_templates.git

# Then in any project
claude-parallel base or ( bmad, spec-kit, all)

# Or as a one-liner without global install
uvx --from git+https://github.com/kingpinzs/claude_parallel_templates.git claude-parallel bmad
```

### Using npx

```bash
npx github:kingpinzs/claude_parallel_templates bmad
```

### Using the install script directly

```bash
# Base template only
./install.sh base /path/to/your/project

# Base + BMAD
./install.sh bmad /path/to/your/project

# Base + Spec Kit
./install.sh spec-kit /path/to/your/project

# All templates
./install.sh all /path/to/your/project
```

## Templates

### Base Template (Required)

Core parallel execution without any spec framework.

```
base/
├── CLAUDE.md                           # Parallel protocol
├── .claude/
│   ├── commands/worktree/
│   │   ├── spawn.md                    # /worktree:spawn
│   │   ├── list.md                     # /worktree:list
│   │   ├── done.md                     # /worktree:done
│   │   └── parallel.md                 # /worktree:parallel
│   ├── skills/parallel-executor/
│   │   ├── SKILL.md                    # Auto-activation
│   │   ├── spawn.sh                    # Spawn agents
│   │   ├── status.sh                   # Check status
│   │   └── merge.sh                    # Merge worktrees
│   └── settings.json                   # Permissions
```

**Commands:**
- `/worktree:spawn auth "Implement authentication"` - Single agent
- `/worktree:parallel "task1, task2, task3"` - Multiple agents
- `/worktree:list` - Show all worktrees
- `/worktree:done` - Merge and cleanup

### BMAD Template

Extends base with BMAD Method v6 integration.

```
bmad/
├── CLAUDE.md                           # BMAD protocol additions
├── .claude/
│   ├── commands/bmad/
│   │   └── parallel-story.md           # /bmad:parallel-story
│   └── skills/bmad-parallel/
│       ├── SKILL.md                    # Auto-parallel after /dev-story
│       └── spawn-story.sh              # Parse and spawn
```

**Workflow:**
```
/workflow-init → /product-brief → /prd → /architecture → /dev-story
                                                              ↓
                                              Auto-parallel detection
                                                              ↓
                                              Worktrees + Claude -p
```

### Spec Kit Template

Extends base with GitHub Spec Kit integration.

```
spec-kit/
├── CLAUDE.md                           # Spec Kit protocol additions
├── .claude/
│   ├── commands/spec/
│   │   └── parallel-tasks.md           # /spec:parallel-tasks
│   └── skills/spec-parallel/
│       ├── SKILL.md                    # Auto-parallel after /tasks
│       └── spawn-tasks.sh              # Parse and spawn
```

**Workflow:**
```
/specify → /plan → /tasks
                      ↓
      Auto-parallel detection
                      ↓
      Worktrees + Claude -p
```

## How It Works

1. **Spec/Task Generation** - Use your preferred method to create tasks
2. **Detection** - Claude identifies parallel-eligible tasks (`[P]` markers)
3. **Worktree Creation** - Each task gets isolated worktree
4. **Agent Spawn** - Headless Claude runs in each worktree
5. **Monitoring** - Watch logs, check status
6. **Merge** - Combine results back to main

## Task Format

Mark parallel-eligible tasks with `[P]`:

```markdown
## Tasks

- [ ] Set up database schema [P]
- [ ] Create REST API endpoints [P]
- [ ] Build frontend components [P]
- [ ] Integration tests [depends: 1,2,3]
```

## Directory Structure (Recommended)

Use the bare repo pattern for clean organization:

```
my-project/
├── .bare/                  # Git database
├── .git                    # Pointer to .bare
├── logs/                   # Agent output logs
├── main/                   # Main branch worktree
│   ├── .claude/            # Templates installed here
│   ├── CLAUDE.md
│   └── src/
├── project-auth/           # Parallel worktree
├── project-api/            # Parallel worktree
└── project-ui/             # Parallel worktree
```

## Setup Bare Repo

```bash
# New project
git clone --bare git@github.com:user/repo.git .bare
echo "gitdir: ./.bare" > .git
git config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git fetch origin
git worktree add main main

# Install templates
cd main
/path/to/install.sh bmad .
```

## Monitoring

```bash
# Watch all agent logs
tail -f ../logs/*.log

# Check status
.claude/skills/parallel-executor/status.sh

# Wait for completion
wait $(cut -d: -f1 ../.parallel-pids)
```

## Merging

```bash
# Merge all completed worktrees
.claude/skills/parallel-executor/merge.sh

# With cleanup
.claude/skills/parallel-executor/merge.sh --cleanup
```

## Customization

Edit `CLAUDE.md` to adjust:
- Parallel triggers (keywords that activate)
- Minimum tasks for auto-parallel (default: 3)
- Maximum parallel agents (default: 10)
- Task detection patterns
- Merge strategy

## Requirements

- Claude Code CLI
- Git 2.20+
- Bash 4+
- (Optional) Node.js for npm projects

## License

MIT
