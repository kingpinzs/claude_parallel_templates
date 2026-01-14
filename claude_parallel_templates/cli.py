#!/usr/bin/env python3
"""CLI for installing Claude Parallel Templates."""

import subprocess
import sys
from pathlib import Path


def get_templates_dir() -> Path:
    """Find the templates directory."""
    # Check if installed as a package (look in share directory)
    share_locations = [
        Path(sys.prefix) / "share" / "claude-parallel",
        Path.home() / ".local" / "share" / "claude-parallel",
    ]

    for loc in share_locations:
        if (loc / "install.sh").exists():
            return loc

    # Fallback: running from source
    source_dir = Path(__file__).parent.parent
    if (source_dir / "install.sh").exists():
        return source_dir

    raise FileNotFoundError(
        "Could not find templates. Ensure claude-parallel is properly installed."
    )


def main():
    """Run the installer."""
    args = sys.argv[1:]
    template = args[0] if args else "base"
    target = args[1] if len(args) > 1 else "."

    templates_dir = get_templates_dir()
    install_script = templates_dir / "install.sh"

    try:
        subprocess.run(
            ["bash", str(install_script), template, target],
            check=True,
            cwd=Path.cwd(),
        )
    except subprocess.CalledProcessError as e:
        sys.exit(e.returncode)


if __name__ == "__main__":
    main()
