---
description: Quickly analyze a goal and spawn parallel agents if tasks are independent
arguments:
  - name: goal
    description: Description of what you want to accomplish
    required: true
---

# /quick-parallel - Fast Goal to Parallel Execution

When the user runs `/quick-parallel "<goal>"`, analyze the goal and determine if it can be parallelized.

## Step 1: Parse Goal

Extract the goal description from the argument. Examples:
- `/quick-parallel "Add OAuth authentication and dark mode toggle"`
- `/quick-parallel "Fix bugs #42 and #38"`
- `/quick-parallel "Refactor auth module and add tests for API"`

## Step 2: Analyze Codebase

Quickly identify relevant modules/directories:

1. **Glob for source directories:**
   - `src/*/`, `lib/*/`, `app/*/`, `packages/*/`

2. **Map goal keywords to modules:**
   - "auth" → `src/auth/`, `lib/auth/`
   - "api" → `src/api/`, `routes/`
   - "ui", "frontend", "theme" → `src/ui/`, `src/components/`
   - "test" → `tests/`, `__tests__/`

3. **Check for keyword overlap** - if multiple parts of the goal map to same directories, they're likely coupled.

## Step 3: Determine Independence

**Tasks are INDEPENDENT if:**
- They touch completely different directories
- No shared imports or dependencies
- Can be tested in isolation
- Merging won't cause conflicts

**Tasks are COUPLED if:**
- They modify the same files
- One depends on the other's output
- They share state (database schema, config, etc.)
- They're parts of the same feature

## Step 4: Present Analysis

### If 2+ Independent Tasks Found:

```
═══════════════════════════════════════════════════════════════
                    Parallel Task Analysis
═══════════════════════════════════════════════════════════════

Goal: "<user goal>"

Analysis: Found 2 independent tasks that can run in parallel.

Tasks:
  1. [ ] <Task 1 description> [P]
     → Affects: src/auth/

  2. [ ] <Task 2 description> [P]
     → Affects: src/ui/theme/

These tasks touch different parts of the codebase and have no dependencies.

Ready to spawn 2 parallel agents? (y/n)
```

**On confirmation:** Execute spawn using `/worktree:parallel`

### If Single Task or Coupled Tasks:

```
═══════════════════════════════════════════════════════════════
                    Task Analysis
═══════════════════════════════════════════════════════════════

Goal: "<user goal>"

Analysis: This is a single cohesive feature. Components depend on each other.

Recommended approach: Work in current session.

Task breakdown:
  1. <Step 1>
  2. <Step 2>
  3. <Step 3>
  ...

Entering plan mode to design implementation...
```

**Then:** Enter plan mode with EnterPlanMode tool

## Examples

### Example 1: Parallelizable
```
/quick-parallel "Add OAuth login and also add a dark mode toggle"

Analysis:
- OAuth → src/auth/ (authentication)
- Dark mode → src/ui/theme/ (UI styling)
- No overlap, independent features

Result: Offer to spawn 2 agents
```

### Example 2: Not Parallelizable
```
/quick-parallel "Add dark mode support"

Analysis:
- Theme state management → src/context/
- CSS variables → src/styles/
- Component updates → src/components/
- Toggle UI → src/components/
- All parts depend on each other

Result: Stay in session, enter plan mode
```

### Example 3: Partially Parallelizable
```
/quick-parallel "Add auth, API endpoints, and integration tests"

Analysis:
- Auth → src/auth/ [P]
- API → src/api/ [P]
- Integration tests → depends on auth AND api

Result: Offer to spawn 2 agents for auth + API
        Queue integration tests for after completion
```

## Important Rules

1. **Always ask for confirmation** before spawning agents
2. **Never spawn for single features** even if they have multiple steps
3. **Maximum 10 agents** - if more tasks, batch them
4. **Default to staying in session** when unsure about independence
5. **Check GitHub issues** if goal references issue numbers
