---
description: Analyze codebase structure without taking action
---

# /analyze - Read-Only Codebase Analysis

When the user runs `/analyze`, perform a comprehensive analysis of the project without taking any action. This is useful for understanding the codebase before deciding what to work on.

## Analysis Steps

### 1. Load Project State

Check if `.claude/.project-state` exists from install:
```bash
if [[ -f ".claude/.project-state" ]]; then
  source .claude/.project-state
fi
```

### 2. Discover Modules

Find all top-level source directories:
- Glob: `src/*/`, `lib/*/`, `app/*/`, `packages/*/`
- Count files in each
- Identify purpose from directory name and contents

### 3. Check GitHub (if available)

If `gh` CLI is available:
```bash
# Open issues
gh issue list --state open --limit 10

# Open PRs
gh pr list --state open --limit 5
```

### 4. Find Code Notes

Search for:
- `TODO:` or `TODO(`
- `FIXME:` or `FIXME(`
- `HACK:` or `XXX:`

### 5. Estimate Test Coverage

- Find test directories: `tests/`, `test/`, `__tests__/`, `spec/`
- Count test files vs source files
- Look for coverage reports: `coverage/`, `.nyc_output/`, `htmlcov/`

## Output Format

```
═══════════════════════════════════════════════════════════════
                    Codebase Analysis
═══════════════════════════════════════════════════════════════

Project: <name from package.json/pyproject.toml/go.mod>
Type: <nodejs/python/go/rust/java/unknown>
Git: <branch name> (<clean/X uncommitted changes>)

Modules
────────────────────────────────────────
  src/auth/        Authentication         12 files
  src/api/         API endpoints          23 files
  src/ui/          Frontend components    45 files
  src/db/          Database layer          8 files
  src/utils/       Shared utilities       15 files

GitHub Issues (5 open)
────────────────────────────────────────
  #42  Add OAuth support              [enhancement]
  #38  Fix login timeout bug          [bug]
  #35  Improve test coverage          [testing]
  #33  Add dark mode                  [enhancement]
  #28  Refactor API responses         [refactor]

GitHub PRs (2 open)
────────────────────────────────────────
  #41  feat: add password reset       (3 days old)
  #39  fix: session expiry            (5 days old)

Code Notes
────────────────────────────────────────
  TODOs:    12 found
  FIXMEs:    3 found
  HACKs:     1 found

Testing
────────────────────────────────────────
  Test files:     34
  Source files:   103
  Ratio:          33%
  Coverage report: coverage/lcov-report/index.html

═══════════════════════════════════════════════════════════════

Run /init to set up for development, or describe what you'd like to work on.
```

## Notes

- This command is READ-ONLY - it never modifies files or spawns agents
- Use this to understand a project before running /init or /quick-parallel
- GitHub data requires the `gh` CLI to be installed and authenticated
- If no GitHub remote, the GitHub sections are skipped
