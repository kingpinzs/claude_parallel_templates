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
│   │   ├── done.md                     # /cpt:done
│   │   └── resume.md                   # /cpt:resume
│   ├── skills/parallel-executor/
│   │   ├── SKILL.md                    # Auto-activation
│   │   ├── spawn.sh                    # Spawn agents + session state
│   │   ├── status.sh                   # Status with phase tracking
│   │   ├── orchestrate.sh              # Monitor & coordinate agents
│   │   ├── merge.sh                    # Merge worktrees
│   │   ├── plan.sh                     # Persistent plan management
│   │   ├── checkpoint.sh               # Record progress checkpoints
│   │   └── resume.sh                   # Resume interrupted sessions
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
- `/cpt:resume` - Resume interrupted parallel session
- `/cpt:plan-status` - Show persistent plan progress
- `/cpt:continue` - Continue working on pending tasks

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
5. **Worktree Creation** - Each task gets isolated git worktree + session state saved
6. **Agent Execution** - Headless Claude runs in each worktree (progress tracked)
7. **Monitoring** - Watch logs or use status.sh for phase-aware progress
8. **Recovery** - If interrupted, resume with `/cpt:resume` (picks up from checkpoints)
9. **Merge** - Combine results back to main with `/cpt:done`

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
├── .parallel-pids          # Running agent PIDs
├── .parallel-scopes        # File scope assignments
├── .parallel-session/      # Session state (crash recovery)
│   ├── session.json        # Master session state
│   └── agents/             # Per-agent progress files
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

# Check status with phase tracking (shows: running/complete, current phase)
.claude/skills/parallel-executor/status.sh

# Orchestrator: Monitor until all complete, then merge automatically
.claude/skills/parallel-executor/orchestrate.sh --auto-merge

# Orchestrator: Monitor only (prompt for merge when done)
.claude/skills/parallel-executor/orchestrate.sh

# Orchestrator with custom poll interval (default 30s)
.claude/skills/parallel-executor/orchestrate.sh --poll-interval=10
```

**Phase Tracking:** Status shows which RALPH phase each agent is in:
- `ralph` - Requirements/Analysis/Logic/Plan/How
- `impl` - TDD Implementation
- `verify` - Verification
- `cleanup` - Code simplification

**Interrupt Handling:** Press Ctrl+C during orchestration to save session state for later resume.

## Merging

```bash
# Merge all completed worktrees
.claude/skills/parallel-executor/merge.sh

# With cleanup (remove worktrees after merge)
.claude/skills/parallel-executor/merge.sh --cleanup
```

## Crash Recovery & Resume

Sessions can be resumed after interruption (Ctrl+C, terminal close, crash):

```bash
# Check if there's a resumable session
.claude/skills/parallel-executor/resume.sh --check-only

# Resume interrupted agents automatically
.claude/skills/parallel-executor/resume.sh

# Or use the command
/cpt:resume
```

**How it works:**
1. Session state saved to `.parallel-session/session.json`
2. Per-agent progress tracked in `.parallel-session/agents/<name>.json`
3. Git commits serve as natural checkpoints
4. Agents announce phase transitions for tracking
5. On resume: agents restart with context from last checkpoint

**Recovery scenarios:**
- **Terminal closed** → Agents continue running (detached), orchestrator can resume monitoring
- **Ctrl+C pressed** → Session marked "interrupted", resume picks up where you left off
- **Agent failed** → Can retry from last checkpoint with full context
- **System crash** → Resume from last git commit, uncommitted changes are stashed

**Auto-cleanup:** Session state is automatically deleted after successful merge.

## Persistent Planning (Cross-Session Continuity)

Plans are stored in git, enabling work to continue across sessions and machines:

```
project/
└── .claude/
    └── parallel-plan.json    # Committed to git
```

### How It Works

1. **Create a plan** with `/cpt:quick "goal"` or let Claude analyze your requirements
2. **Tasks are tracked** in the manifest with status (pending/in_progress/merged)
3. **Spawn updates the plan** - tasks marked `in_progress` with branch name
4. **Merge updates the plan** - tasks marked `merged` after successful merge
5. **Pull on any machine** - Claude auto-detects the plan and shows status

### Workflow Example

**Day 1: Start the project**
```bash
/cpt:quick "Build authentication system"

# Claude creates plan with tasks:
# - oauth-client [P]
# - password-reset [P]
# - 2fa (depends: oauth-client)
# - session-management [P]

# Spawns 3 independent agents
# Work completes, you merge and push
```

**Day 2: Continue on another machine**
```bash
git pull

# Claude detects active plan on startup:
# "Active plan: Build authentication system"
# "3 tasks merged, 1 pending (2fa)"

/cpt:continue    # Spawns agent for 2fa (dependency now met)
/cpt:done        # Merge final work
# Plan marked "completed"
```

### Commands

```bash
# View plan status
/cpt:plan-status

# Continue with pending tasks
/cpt:continue

# Archive completed plan and start fresh
.claude/skills/parallel-executor/plan.sh archive
```

### Plan Schema

```json
{
  "plan_id": "plan_20260114_abc123",
  "goal": "Build authentication system",
  "status": "in_progress",
  "tasks": [
    {"id": "oauth", "status": "merged", "depends_on": []},
    {"id": "2fa", "status": "pending", "depends_on": ["oauth"]}
  ]
}
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
- jq (recommended for crash recovery features)
- (Optional) Node.js for npm projects

Install jq if not present:
```bash
# Ubuntu/Debian
sudo apt install jq

# macOS
brew install jq
```

## License

MIT
