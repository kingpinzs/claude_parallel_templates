# /cpt:init - Initialize Parallel Development

When the user runs /cpt:init, perform the following initialization process:

## Step 1: Project Detection

Analyze the current project state:

1. **Check for existing configuration:**
   - Does CLAUDE.md exist? If yes, read it and note existing instructions
   - Does .claude/ directory exist? Note existing commands/skills
   - Is this a git repository? Check git status
   - Is this a bare repo setup already? (check for .bare/ or worktree structure)

2. **Detect project type:**
   - Check for package.json (Node.js)
   - Check for pyproject.toml, setup.py, requirements.txt (Python)
   - Check for go.mod (Go)
   - Check for Cargo.toml (Rust)
   - Check for pom.xml, build.gradle (Java)
   - Check for Gemfile (Ruby)
   - Check for other indicators

3. **Analyze project structure:**
   - Identify source directories (src/, lib/, app/, etc.)
   - Identify test directories (test/, tests/, __tests__/, spec/)
   - Identify config files
   - Identify documentation
   - Note the overall architecture pattern (monolith, monorepo, microservices)

4. **Check for existing tooling:**
   - CI/CD configuration (.github/workflows/, .gitlab-ci.yml, etc.)
   - Linting/formatting configs (eslint, prettier, ruff, etc.)
   - Build tools (webpack, vite, esbuild, etc.)
   - Test frameworks

## Step 2: Ask Clarifying Questions

Based on detection, ask the user:

1. **If CLAUDE.md exists:**
   - "I found an existing CLAUDE.md. Should I merge parallel development instructions into it, or replace it?"

2. **Project context:**
   - "What is this project? (brief description)"
   - "What are the main areas/modules of this codebase?"

3. **Development workflow:**
   - "How do you typically run tests?" (if not auto-detected)
   - "How do you build/compile the project?" (if not auto-detected)
   - "Any specific coding conventions I should follow?"

4. **Parallelization goals:**
   - "What kind of tasks do you want to parallelize?"
     - [ ] Feature development
     - [ ] Bug fixes
     - [ ] Refactoring
     - [ ] Testing
     - [ ] Documentation
     - [ ] All of the above

## Step 3: Generate Project-Specific CLAUDE.md

Create or update CLAUDE.md with:

1. **Project overview** (from user input and detection)
2. **Build/test commands** (detected + confirmed)
3. **Architecture notes** (detected patterns)
4. **Parallel development protocol** (from base template)
5. **Project-specific task patterns** (what makes sense to parallelize)

## Step 4: Enter Plan Mode

After initialization, automatically enter plan mode to:

1. Present a summary of the project analysis
2. Identify potential areas for parallel development
3. Suggest an initial task breakdown if the user has a goal in mind
4. Wait for user approval before any implementation

## Output Format

```
═══════════════════════════════════════════════════════════════
                    Parallel Development Init
═══════════════════════════════════════════════════════════════

📁 Project Detection
────────────────────
Type: [detected type]
Root: [project root]
Git: [yes/no, branch info]
Existing CLAUDE.md: [yes/no]

📦 Detected Stack
────────────────────
Language: [detected]
Framework: [detected]
Build: [command]
Test: [command]
Lint: [command]

🏗️ Architecture
────────────────────
Pattern: [monolith/monorepo/etc]
Main directories:
  - src/: [description]
  - tests/: [description]
  ...

❓ Questions
────────────────────
[Ask clarifying questions here]
```

After gathering information, proceed to generate CLAUDE.md and enter plan mode.
