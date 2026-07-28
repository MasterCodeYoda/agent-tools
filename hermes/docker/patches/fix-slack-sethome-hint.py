#!/usr/bin/env python3
"""Patch Hermes home-channel onboarding hint for Slack.

Upstream gateway/run.py tells Slack users to type ``/hermes sethome``. That only
works when the Slack app registers the ``/hermes`` slash command. Without it,
Slack intercepts the leading slash and shows "not a valid command", and Hermes
never sees the text.

Jarvis day-1 apps often run Socket Mode with events only (no full slash
registry). Hermes already rewrites known bang-prefix commands (``!sethome`` →
``/sethome``) for Slack messages — that path always works as a normal DM.

Idempotent: safe to re-run on already-patched trees.
"""
from __future__ import annotations

import sys
from pathlib import Path

TARGETS = [
    Path("/opt/hermes/gateway/run.py"),
    # Local/dev checkout layout (if ever used)
    Path("gateway/run.py"),
]

# Minimal, stable anchor — Hermes uses this exact pair today.
OLD_SLACK_CMD = '"/hermes sethome"'
NEW_SLACK_CMD = '"!sethome"'

# Optional fuller notice rewrite if the f-string shape is still present.
OLD_NOTICE_LINE = (
    'f"Type {sethome_cmd} to make this chat your home channel, "'
)
# Literal source text written into run.py (not evaluated here).
NEW_NOTICE_LINE = (
    'f"Type {sethome_cmd} to make this chat your home channel '
    '(Slack: bang form; bare / is a workspace slash command), "'
)


def patch_file(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    original = text
    if OLD_SLACK_CMD in text:
        text = text.replace(OLD_SLACK_CMD, NEW_SLACK_CMD, 1)
    # Comment accuracy (best-effort; non-fatal if drift)
    text = text.replace(
        "# Slack dispatches all Hermes commands through a single\n"
        "                # parent slash command `/hermes`; bare `/sethome` is not\n"
        '                # registered and would fail with "app did not respond".',
        "# Slack: prefer bang form. Bare /… is intercepted by Slack unless the\n"
        "                # app registers native slash commands (/sethome, /hermes).\n"
        "                # Hermes rewrites !sethome → /sethome on inbound messages.",
        1,
    )
    if OLD_NOTICE_LINE in text:
        text = text.replace(OLD_NOTICE_LINE, NEW_NOTICE_LINE, 1)
    if text == original:
        # Already patched or string drifted — report via return
        if NEW_SLACK_CMD in text and OLD_SLACK_CMD not in text:
            print(f"already patched: {path}", file=sys.stderr)
            return True
        print(f"no match in {path} (Hermes upstream may have changed)", file=sys.stderr)
        return False
    path.write_text(text, encoding="utf-8")
    print(f"patched: {path}", file=sys.stderr)
    return True


def main() -> int:
    ok = False
    for t in TARGETS:
        if patch_file(t):
            ok = True
    if not ok:
        print("fix-slack-sethome-hint: no file patched", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
