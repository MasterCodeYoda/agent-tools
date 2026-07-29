#!/usr/bin/env python3
"""Redirect Hermes /update (!update) to jarvis-host image check.

Upstream ``/update`` runs ``hermes update`` against a git checkout of Hermes.
In jarvis-hermes that fails with "Not a git repository — cannot update."

For Jarvis CoS, ``!update`` / ``/update`` means: queue a **host kit** image
check (``update-check-request.json``). Apply still needs a separate "yes".

Idempotent.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

TARGETS = [
    Path("/opt/hermes/gateway/slash_commands.py"),
    Path("gateway/slash_commands.py"),
]

HELPER_NAME = "_handle_jarvis_host_update_command"

HELPER = r'''
    async def _handle_jarvis_host_update_command(self, event: MessageEvent) -> str:
        """Jarvis CoS: !update / /update → host kit image check (not hermes git)."""
        import json
        import os
        from datetime import datetime, timezone
        from pathlib import Path as _P

        home = _P(os.environ.get("HERMES_HOME", "/opt/data"))
        ops = home / "profiles" / "jarvis" / "state" / "ops"
        ops.mkdir(parents=True, exist_ok=True)
        now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        req = {
            "schema": "jarvis-host.update-check-request/v1",
            "action": "check",
            "requested_at": now,
            "requested_by": f"slack:{getattr(event.source, 'user_id', None) or 'unknown'}",
        }
        path = ops / "update-check-request.json"
        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps(req, indent=2) + "\n", encoding="utf-8")
        tmp.replace(path)

        status_path = ops / "update-status.json"
        extra = ""
        if status_path.is_file():
            try:
                st = json.loads(status_path.read_text(encoding="utf-8"))
                if st.get("available") is True:
                    extra = (
                        "\n\n_Last status already shows an update available. "
                        "Reply **yes** to apply, or wait ~1m for a fresh check._"
                    )
                elif st.get("checked_at"):
                    extra = (
                        f"\n\n_Last check: {st.get('checked_at')} — "
                        f"available={st.get('available')}_"
                    )
            except Exception:
                pass

        return (
            "Host image **check** requested (`jarvis-host`). "
            "The host polls within about a minute and writes `update-status.json`.\n\n"
            "• If an update is available, reply **yes** / **apply update** to recreate "
            "the container (volume kept).\n"
            "• This is **not** a Hermes git self-update."
            f"{extra}"
        )

'''

EARLY_RETURN = """        # --- jarvis-hermes: host image check, not hermes git self-update ---
        try:
            return await self._handle_jarvis_host_update_command(event)
        except Exception as _jh_exc:
            return (
                "✗ Host update check failed to queue "
                f"({type(_jh_exc).__name__}: {_jh_exc}). "
                "Operator can run: jarvis-host update --check"
            )
        # --- end jarvis-hermes ---
"""


def patch_file(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8")
    original = text

    # 1) Ensure helper method exists (once)
    if HELPER_NAME not in text:
        # Insert before a stable sibling method
        placed = False
        for needle in (
            "\n    async def _handle_sethome",
            "\n    async def _handle_restart",
            "\n    async def _handle_status_command",
            "\n    async def _handle_help",
        ):
            j = text.find(needle)
            if j > 0:
                text = text[:j] + "\n" + HELPER + text[j:]
                placed = True
                break
        if not placed:
            # Fallback: before end of SlashCommandMixin class is hard; fail
            print(f"could not place helper in {path}", file=sys.stderr)
            return False

    # 2) Early-return at start of _handle_update_command body
    if "return await self._handle_jarvis_host_update_command(event)" not in text:
        # Match method signature + docstring end, inject after docstring
        m = re.search(
            r"(async def _handle_update_command\(self, event: MessageEvent\) -> str:\n"
            r'        """Handle /update command.*?"""\n)',
            text,
            flags=re.DOTALL,
        )
        if not m:
            print(f"no _handle_update_command docstring match in {path}", file=sys.stderr)
            return False
        text = text[: m.end()] + EARLY_RETURN + text[m.end() :]

    if text == original:
        print(f"already patched: {path}", file=sys.stderr)
        return True

    path.write_text(text, encoding="utf-8")
    print(f"patched: {path}", file=sys.stderr)
    return True


def main() -> int:
    ok = False
    for t in TARGETS:
        if patch_file(t):
            ok = True
    if not ok:
        print("fix-jarvis-host-update-slash: no file patched", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
