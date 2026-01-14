#!/bin/bash
# Claude Parallel Templates Installer
# Usage: ./install.sh [base|bmad|spec-kit|all] [target-directory]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${1:-base}"
TARGET="${2:-.}"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[install]${NC} $1"; }
warn() { echo -e "${YELLOW}[install]${NC} $1"; }
info() { echo -e "${BLUE}[install]${NC} $1"; }

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "       Claude Code Parallel Development Templates"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Validate template
case "$TEMPLATE" in
    base|bmad|spec-kit|all)
        ;;
    *)
        echo "Usage: $0 [base|bmad|spec-kit|all] [target-directory]"
        echo ""
        echo "Templates:"
        echo "  base      - Core parallel execution (required)"
        echo "  bmad      - BMAD Method integration"
        echo "  spec-kit  - GitHub Spec Kit integration"
        echo "  all       - Install all templates"
        exit 1
        ;;
esac

# Create target directory
mkdir -p "$TARGET"
cd "$TARGET"
TARGET=$(pwd)

log "Installing to: $TARGET"
echo ""

# Detect project state
detect_project() {
    info "Detecting project state..."

    # Check for existing CLAUDE.md
    if [[ -f "CLAUDE.md" ]]; then
        EXISTING_CLAUDE_MD="true"
        warn "Found existing CLAUDE.md"
    else
        EXISTING_CLAUDE_MD="false"
    fi

    # Check if git repo
    if git rev-parse --git-dir > /dev/null 2>&1; then
        IS_GIT_REPO="true"
        GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
        log "Git repository detected (branch: $GIT_BRANCH)"
    else
        IS_GIT_REPO="false"
        warn "Not a git repository - parallel worktrees require git"
    fi

    # Check for bare repo setup
    if [[ -d ".bare" ]] || [[ -f ".git" && $(cat .git 2>/dev/null) == gitdir:* ]]; then
        IS_BARE_REPO="true"
        log "Bare repo pattern detected"
    else
        IS_BARE_REPO="false"
    fi

    # Detect project type
    if [[ -f "package.json" ]]; then
        PROJECT_TYPE="nodejs"
        log "Detected: Node.js project"
    elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
        PROJECT_TYPE="python"
        log "Detected: Python project"
    elif [[ -f "go.mod" ]]; then
        PROJECT_TYPE="go"
        log "Detected: Go project"
    elif [[ -f "Cargo.toml" ]]; then
        PROJECT_TYPE="rust"
        log "Detected: Rust project"
    elif [[ -f "pom.xml" ]] || [[ -f "build.gradle" ]]; then
        PROJECT_TYPE="java"
        log "Detected: Java project"
    else
        PROJECT_TYPE="unknown"
        info "Project type: unknown (will ask during init)"
    fi

    # Check if brownfield (has existing code)
    if [[ -d "src" ]] || [[ -d "lib" ]] || [[ -d "app" ]] || find . -maxdepth 2 -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.go" -o -name "*.rs" 2>/dev/null | head -1 | grep -q .; then
        IS_BROWNFIELD="true"
        log "Brownfield project (existing code detected)"
    else
        IS_BROWNFIELD="false"
        log "Greenfield project (no existing code detected)"
    fi
}

# Install base (always required)
install_base() {
    info "Installing base template..."

    # Detect project state first
    detect_project

    # Clean up old command structure (for updates from older versions)
    rm -rf .claude/commands/worktree 2>/dev/null || true
    rm -f .claude/commands/init.md 2>/dev/null || true
    rm -f .claude/commands/analyze.md 2>/dev/null || true
    rm -f .claude/commands/quick-parallel.md 2>/dev/null || true

    # Create directories
    mkdir -p .claude/commands/cpt
    mkdir -p .claude/skills/parallel-executor

    # Handle CLAUDE.md based on existing state
    if [[ "$EXISTING_CLAUDE_MD" == "true" ]]; then
        # Backup existing and append parallel protocol
        cp CLAUDE.md CLAUDE.md.backup
        log "Backed up existing CLAUDE.md to CLAUDE.md.backup"
        echo "" >> ./CLAUDE.md
        echo "# Parallel Development Protocol" >> ./CLAUDE.md
        echo "" >> ./CLAUDE.md
        cat "$SCRIPT_DIR/base/CLAUDE.md" >> ./CLAUDE.md
    else
        cp "$SCRIPT_DIR/base/CLAUDE.md" ./CLAUDE.md
    fi

    # Copy commands and skills
    mkdir -p .claude/commands/cpt
    cp -r "$SCRIPT_DIR/base/.claude/commands/cpt/"* .claude/commands/cpt/
    cp -r "$SCRIPT_DIR/base/.claude/skills/parallel-executor/"* .claude/skills/parallel-executor/
    cp "$SCRIPT_DIR/base/.claude/settings.json" .claude/settings.json 2>/dev/null || true

    # Make scripts executable
    chmod +x .claude/skills/parallel-executor/*.sh 2>/dev/null || true

    log "Base template installed"

    # Store detection results for later use
    echo "EXISTING_CLAUDE_MD=$EXISTING_CLAUDE_MD" > .claude/.project-state
    echo "IS_GIT_REPO=$IS_GIT_REPO" >> .claude/.project-state
    echo "IS_BARE_REPO=$IS_BARE_REPO" >> .claude/.project-state
    echo "PROJECT_TYPE=$PROJECT_TYPE" >> .claude/.project-state
    echo "IS_BROWNFIELD=$IS_BROWNFIELD" >> .claude/.project-state
    echo "TEMPLATE=$TEMPLATE" >> .claude/.project-state
}

# Install BMAD additions
install_bmad() {
    info "Installing BMAD template..."

    # Auto-install bmad-method if not already installed
    if ! command -v bmad &> /dev/null && [[ ! -d ".bmad" ]]; then
        info "bmad-method not found, installing via npx..."

        # Install Node.js/npm if not available
        if ! command -v npx &> /dev/null; then
            info "npx not found, installing Node.js..."
            curl -fsSL https://fnm.vercel.app/install | bash
            export PATH="$HOME/.local/share/fnm:$PATH"
            eval "$(fnm env)"
            fnm install --lts
            log "Node.js installed"
        fi

        npx bmad-method@alpha install
        log "bmad-method installed"
    else
        log "bmad-method already installed"
    fi

    mkdir -p .claude/commands/bmad
    mkdir -p .claude/skills/bmad-parallel

    cp -r "$SCRIPT_DIR/bmad/.claude/commands/bmad/"* .claude/commands/bmad/
    cp -r "$SCRIPT_DIR/bmad/.claude/skills/bmad-parallel/"* .claude/skills/bmad-parallel/

    # Append CLAUDE.md additions
    echo "" >> ./CLAUDE.md
    cat "$SCRIPT_DIR/bmad/CLAUDE.md" >> ./CLAUDE.md

    # Make scripts executable
    chmod +x .claude/skills/bmad-parallel/*.sh 2>/dev/null || true

    log "BMAD template installed"
}

# Install Spec Kit additions
install_speckit() {
    info "Installing Spec Kit template..."

    # Auto-install specify-cli if not available
    if ! command -v specify &> /dev/null; then
        info "specify-cli not found, installing via uv..."

        # Install uv if not available
        if ! command -v uv &> /dev/null; then
            info "uv not found, installing..."
            curl -LsSf https://astral.sh/uv/install.sh | sh
            # Source the environment to make uv available
            export PATH="$HOME/.local/bin:$PATH"
            log "uv installed"
        fi

        uv tool install specify-cli --from git+https://github.com/github/spec-kit.git
        log "specify-cli installed"
    else
        log "specify-cli already installed"
    fi

    mkdir -p .claude/commands/spec
    mkdir -p .claude/skills/spec-parallel

    cp -r "$SCRIPT_DIR/spec-kit/.claude/commands/spec/"* .claude/commands/spec/
    cp -r "$SCRIPT_DIR/spec-kit/.claude/skills/spec-parallel/"* .claude/skills/spec-parallel/

    # Append CLAUDE.md additions
    echo "" >> ./CLAUDE.md
    cat "$SCRIPT_DIR/spec-kit/CLAUDE.md" >> ./CLAUDE.md

    # Make scripts executable
    chmod +x .claude/skills/spec-parallel/*.sh 2>/dev/null || true

    log "Spec Kit template installed"
}

# Install based on selection
case "$TEMPLATE" in
    base)
        install_base
        ;;
    bmad)
        install_base
        install_bmad
        ;;
    spec-kit)
        install_base
        install_speckit
        ;;
    all)
        install_base
        install_bmad
        install_speckit
        ;;
esac

echo ""
echo "═══════════════════════════════════════════════════════════"
log "Installation complete!"
echo ""
echo "Installed files:"
find .claude -type f \( -name "*.md" -o -name "*.sh" -o -name "*.json" \) 2>/dev/null | head -20
echo ""

# Show detection summary
echo "Project Detection Summary:"
echo "────────────────────────────"
if [[ -f ".claude/.project-state" ]]; then
    source .claude/.project-state
    echo "  Type: $PROJECT_TYPE"
    echo "  Git repo: $IS_GIT_REPO"
    echo "  Bare repo: $IS_BARE_REPO"
    echo "  Brownfield: $IS_BROWNFIELD"
    echo "  Existing CLAUDE.md: $EXISTING_CLAUDE_MD"
fi
echo ""

# Commands available
echo "Commands available:"
echo "────────────────────────────"
echo "  /cpt:init                  - Initialize and analyze project"
echo "  /cpt:analyze               - Read-only codebase analysis"
echo "  /cpt:quick <goal>          - Fast goal → parallel breakdown"
echo "  /cpt:spawn <name> <prompt> - Spawn single parallel agent"
echo "  /cpt:parallel <tasks>      - Spawn multiple agents"
echo "  /cpt:list                  - List worktrees"
echo "  /cpt:done                  - Merge and cleanup"

if [[ "$TEMPLATE" == "bmad" ]] || [[ "$TEMPLATE" == "all" ]]; then
    echo "  /workflow-init             - Start BMAD workflow"
    echo "  /bmad:parallel-story       - BMAD story parallel"
fi

if [[ "$TEMPLATE" == "spec-kit" ]] || [[ "$TEMPLATE" == "all" ]]; then
    echo "  /specify                   - Start Spec Kit workflow"
    echo "  /spec:parallel-tasks       - Spec Kit parallel"
fi

echo ""

# Recommend bare repo if not already set up
if [[ "$IS_GIT_REPO" == "true" ]] && [[ "$IS_BARE_REPO" != "true" ]]; then
    echo "Tip: For better worktree management, consider the bare repo pattern:"
    echo "────────────────────────────"
    echo "  git clone --bare \$(git remote get-url origin) .bare"
    echo "  echo 'gitdir: ./.bare' > .git"
    echo "  git worktree add main main"
    echo ""
fi

# Auto-launch Claude with /cpt:init
echo ""
log "Launching Claude Code..."
echo ""
exec claude -p "/cpt:init"
