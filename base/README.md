# Claude Code Parallel Development - Base Template

A minimal setup for parallel Claude Code sessions using git worktrees.

## Quick Start

```bash
# 1. Copy this template to your project
cp -r /path/to/base/.claude /your/project/
cp /path/to/base/CLAUDE.md /your/project/

# 2. Set up bare repo pattern (recommended)
cd /your/project
mv .git .git-backup
git clone --bare $(git -C .git-backup config --get remote.origin.url) .bare
echo "gitdir: ./.bare" > .git
git worktree add main main
mv .git-backup/.. main/  # Move your files
rm -rf .git-backup

# 3. Start Claude
cd main
claude
```

## What's Included

```
.claude/
├── commands/
│   └── cpt/
│       ├── init.md       # /cpt:init - Initialize project
│       ├── analyze.md    # /cpt:analyze - Read-only analysis
│       ├── quick.md      # /cpt:quick - Fast goal breakdown
│       ├── spawn.md      # /cpt:spawn <name> <prompt>
│       ├── parallel.md   # /cpt:parallel <tasks>
│       ├── list.md       # /cpt:list
│       └── done.md       # /cpt:done
├── skills/
│   └── parallel-executor/
│       ├── SKILL.md      # Auto-activates on parallel triggers
│       └── spawn.sh      # Spawns headless Claude instances
└── settings.json         # Hooks configuration

CLAUDE.md                 # Parallel execution protocol
```

## Usage

### Manual Commands
```
/cpt:init                                    # Initialize and analyze project
/cpt:spawn auth-feature "Implement auth"     # Spawn single agent
/cpt:parallel "task1, task2, task3"          # Spawn multiple agents
/cpt:list                                    # List worktrees
/cpt:done                                    # Merge and cleanup
```

### Automatic (via CLAUDE.md)
Just describe a feature with multiple components - Claude will offer to parallelize.

### Direct Script
```bash
.claude/skills/parallel-executor/spawn.sh "task 1" "task 2" "task 3"
```

## Customization

Edit `CLAUDE.md` to adjust:
- Parallel triggers (keywords that activate parallel mode)
- Task detection patterns
- Merge strategy
- Cleanup behavior
