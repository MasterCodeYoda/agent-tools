"""Command registry + dispatcher for taskcli.

Each command is a handler `def handler(argv: list[str], store_path: Path) -> int`
returning a process exit code. New commands register in the COMMANDS dict below,
at the marked insertion point.
"""

from __future__ import annotations

import sys
from pathlib import Path

from . import __version__

DEFAULT_STORE = Path("tasks.json")


def cmd_version(argv: list[str], store_path: Path) -> int:
    """Print the taskcli version."""
    print(f"taskcli {__version__}")
    return 0


# Command registry. Map command name -> handler.
# Register new commands ABOVE the end-marker line so additions cluster here.
COMMANDS = {
    "version": cmd_version,
    # <<< register new commands above this line >>>
}


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv or argv[0] in ("-h", "--help"):
        print("usage: taskcli <command> [args]")
        print("commands: " + ", ".join(sorted(COMMANDS)))
        return 0
    name, rest = argv[0], argv[1:]
    handler = COMMANDS.get(name)
    if handler is None:
        print(f"unknown command: {name}", file=sys.stderr)
        return 2
    return handler(rest, DEFAULT_STORE)


if __name__ == "__main__":
    raise SystemExit(main())
