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

# Install base (always required)
install_base() {
    info "Installing base template..."

    # Create directories
    mkdir -p .claude/commands/worktree
    mkdir -p .claude/skills/parallel-executor

    # Copy files
    cp "$SCRIPT_DIR/base/CLAUDE.md" ./CLAUDE.md 2>/dev/null || \
        cat "$SCRIPT_DIR/base/CLAUDE.md" >> ./CLAUDE.md

    cp -r "$SCRIPT_DIR/base/.claude/commands/worktree/"* .claude/commands/worktree/
    cp -r "$SCRIPT_DIR/base/.claude/skills/parallel-executor/"* .claude/skills/parallel-executor/
    cp "$SCRIPT_DIR/base/.claude/settings.json" .claude/settings.json 2>/dev/null || true

    # Make scripts executable
    chmod +x .claude/skills/parallel-executor/*.sh 2>/dev/null || true

    log "Base template installed"
}

# Install BMAD additions
install_bmad() {
    info "Installing BMAD template..."

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
    warn "For full BMAD, also install: https://github.com/aj-geddes/claude-code-bmad-skills"
}

# Install Spec Kit additions
install_speckit() {
    info "Installing Spec Kit template..."

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
    warn "For full Spec Kit, also run: npx speckit init . --ai claude"
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
find .claude -type f -name "*.md" -o -name "*.sh" -o -name "*.json" 2>/dev/null | head -20
echo ""
echo "Next steps:"
echo "  1. Review and customize CLAUDE.md"
echo "  2. Set up bare repo pattern (recommended):"
echo "     git clone --bare <url> .bare"
echo "     echo 'gitdir: ./.bare' > .git"
echo "     git worktree add main main"
echo "  3. Start Claude: cd main && claude"
echo ""
echo "Commands available:"
echo "  /worktree:spawn <name> <prompt>  - Spawn parallel agent"
echo "  /worktree:list                   - List worktrees"
echo "  /worktree:parallel <tasks>       - Spawn multiple agents"
echo "  /worktree:done                   - Merge and cleanup"

if [[ "$TEMPLATE" == "bmad" ]] || [[ "$TEMPLATE" == "all" ]]; then
    echo "  /bmad:parallel-story <file>      - BMAD story parallel"
fi

if [[ "$TEMPLATE" == "spec-kit" ]] || [[ "$TEMPLATE" == "all" ]]; then
    echo "  /spec:parallel-tasks <file>      - Spec Kit parallel"
fi

echo ""
