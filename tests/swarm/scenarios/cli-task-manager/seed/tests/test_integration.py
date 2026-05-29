"""Shared cross-command integration tests. Every backlog item must keep these green.

These guard on COMMANDS membership so they pass on the seed (only `version`
registered) and stay green as commands are added — until a command violates a
cross-cutting invariant. In particular, read-only commands must succeed on a
*fresh, empty* store (a classic edge case).
"""

import tempfile
from pathlib import Path

from taskcli.cli import COMMANDS


def test_help_for_every_command():
    """The dispatcher's help path lists every registered command."""
    from taskcli.cli import main

    rc = main(["--help"])
    assert rc == 0


def test_readonly_commands_on_empty_store():
    """Read-only commands must exit 0 against a freshly-initialized empty store.

    Guarded by COMMANDS membership: vacuously true until `list`/`stats` exist.
    """
    for name in ("list", "stats"):
        handler = COMMANDS.get(name)
        if handler is None:
            continue
        with tempfile.TemporaryDirectory() as d:
            store = Path(d) / "tasks.json"
            rc = handler([], store)
            assert rc == 0, f"{name} failed on an empty store (rc={rc})"
