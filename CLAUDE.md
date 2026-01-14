# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a template repository providing drop-in configurations for running parallel Claude Code sessions using git worktrees. It contains three template variants:

- **base/** - Core parallel execution (always required)
- **bmad/** - BMAD Method v6 integration extension
- **spec-kit/** - GitHub Spec Kit integration extension

## Installation

```bash
./install.sh base /path/to/project      # Base only
./install.sh bmad /path/to/project      # Base + BMAD
./install.sh spec-kit /path/to/project  # Base + Spec Kit
./install.sh all /path/to/project       # All templates
```

## Template Structure

Each template contains:
- `CLAUDE.md` - Protocol instructions appended to target project
- `.claude/commands/` - Slash commands (e.g., `/worktree:spawn`)
- `.claude/skills/` - Auto-activating skills with shell scripts
- `.claude/settings.json` - Permissions configuration

## Key Concepts

### Parallel Execution Flow

1. Tasks marked with `[P]` are identified as parallel-eligible
2. Each task gets its own git worktree (`git worktree add`)
3. Headless Claude instances run in each worktree (`claude -p --dangerously-skip-permissions`)
4. Output captured to `../logs/*.log`
5. Results merged back to main branch

### Task Independence Rules

Tasks are parallel-safe when they:
- Touch different files/directories
- Have no shared state dependencies
- Don't modify shared configuration

Tasks require sequencing when they:
- Modify the same files
- Have `[depends: X]` markers
- Share database migrations

### Bare Repo Pattern

The recommended setup uses git's bare repository pattern:
```
project/
├── .bare/              # Git database
├── .git                # Pointer to .bare
├── logs/               # Agent output
├── main/               # Main worktree (templates installed here)
└── project-feature/    # Parallel worktrees
```

## Modifying Templates

When editing template files:
- `base/CLAUDE.md` contains the parallel protocol rules
- Shell scripts in `skills/*/` do the actual worktree and process management
- Commands in `commands/*/` are user-facing slash commands

The install script concatenates CLAUDE.md files when installing multiple templates (base is always first).
