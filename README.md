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
# First install or update (use --no-cache to ensure latest)
npx --no-cache github:kingpinzs/claude_parallel_templates bmad
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
│   ├── commands/cpt/
│   │   ├── init.md                     # /cpt:init
│   │   ├── analyze.md                  # /cpt:analyze
│   │   ├── quick.md                    # /cpt:quick
│   │   ├── spawn.md                    # /cpt:spawn
│   │   ├── parallel.md                 # /cpt:parallel
│   │   ├── list.md                     # /cpt:list
│   │   └── done.md                     # /cpt:done
│   ├── skills/parallel-executor/
│   │   ├── SKILL.md                    # Auto-activation
│   │   ├── spawn.sh                    # Spawn agents
│   │   ├── status.sh                   # Check status
│   │   └── merge.sh                    # Merge worktrees
│   └── settings.json                   # Permissions
```

**Commands:**
- `/cpt:init` - Initialize and analyze project (auto-runs after install)
- `/cpt:analyze` - Read-only codebase analysis
- `/cpt:quick "goal"` - Fast goal → parallel breakdown
- `/cpt:spawn auth "Implement authentication"` - Single agent
- `/cpt:parallel "task1, task2, task3"` - Multiple agents
- `/cpt:list` - Show all worktrees
- `/cpt:done` - Merge and cleanup

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

1. **Install** - Run the installer (Claude auto-launches with `/cpt:init`)
2. **Analyze** - `/cpt:init` analyzes your codebase and asks clarifying questions
3. **Plan** - Describe your goal; Claude creates task breakdown with `[P]` markers for independent tasks
4. **Spawn** - If 2+ independent tasks exist, Claude asks to spawn parallel agents
5. **Worktree Creation** - Each task gets isolated git worktree
6. **Agent Execution** - Headless Claude runs in each worktree
7. **Monitoring** - Watch logs with `tail -f ../logs/*.log`
8. **Merge** - Combine results back to main with `/cpt:done`

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

## Monitoring & Orchestration

```bash
# Watch all agent logs
tail -f ../logs/*.log

# Check status (one-time)
.claude/skills/parallel-executor/status.sh

# Orchestrator: Monitor until all complete, then merge automatically
.claude/skills/parallel-executor/orchestrate.sh --auto-merge

# Orchestrator: Monitor only (prompt for merge when done)
.claude/skills/parallel-executor/orchestrate.sh

# Orchestrator with custom poll interval (default 30s)
.claude/skills/parallel-executor/orchestrate.sh --poll-interval=10
```

## Merging

```bash
# Merge all completed worktrees
.claude/skills/parallel-executor/merge.sh

# With cleanup (remove worktrees after merge)
.claude/skills/parallel-executor/merge.sh --cleanup
```

## Updating

To update an existing installation to the latest version, simply re-run the installer:

```bash
# Using uv (re-running overwrites with latest)
uvx --from git+https://github.com/kingpinzs/claude_parallel_templates.git claude-parallel base .

# Using npx (use --no-cache to bypass npm cache)
npx --no-cache github:kingpinzs/claude_parallel_templates base .

# Using install script (pull latest first)
cd /path/to/claude_parallel_templates
git pull origin main
./install.sh base /path/to/your/project
```

Your `.claude/.project-state` and any project-specific CLAUDE.md customizations will be preserved (CLAUDE.md is backed up to CLAUDE.md.backup before updating).

## Customization

Edit `CLAUDE.md` to adjust:
- Parallel triggers (keywords that activate)
- Minimum tasks for auto-parallel (default: 2)
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
