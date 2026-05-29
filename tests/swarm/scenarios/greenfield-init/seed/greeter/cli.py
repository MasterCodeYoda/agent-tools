"""Auto-discovering command dispatcher for greeter.

Commands live as modules under `greeter/commands/`, each exposing `NAME: str`
and `run(argv: list[str]) -> int`. New commands are added as new modules — no
central registry to edit — so independent commands never collide at merge.
"""

from __future__ import annotations

import importlib
import pkgutil
import sys

from . import commands as _commands_pkg


def discover() -> dict:
    """Discover registered commands as {name: run}."""
    found = {}
    for mod_info in pkgutil.iter_modules(_commands_pkg.__path__):
        mod = importlib.import_module(f"greeter.commands.{mod_info.name}")
        name = getattr(mod, "NAME", None)
        run = getattr(mod, "run", None)
        if name and callable(run):
            found[name] = run
    return found


def main(argv: list[str] | None = None) -> int:
    argv = list(sys.argv[1:] if argv is None else argv)
    commands = discover()
    if not argv or argv[0] in ("-h", "--help"):
        print("usage: greeter <command> [args]")
        print("commands: " + (", ".join(sorted(commands)) or "(none)"))
        return 0
    name, rest = argv[0], argv[1:]
    run = commands.get(name)
    if run is None:
        print(f"unknown command: {name}", file=sys.stderr)
        return 2
    return run(rest)


if __name__ == "__main__":
    raise SystemExit(main())
