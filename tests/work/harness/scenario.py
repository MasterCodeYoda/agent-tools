"""Minimal scenario.yml loader (stdlib only — no PyYAML)."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Scenario:
    name: str
    purpose: str = ""
    unit_path: str = ".agent-tools/planning/smoke-unit"
    hard_invariants: list[str] = field(default_factory=list)
    observation_checklist: list[dict[str, str]] = field(default_factory=list)
    harnesses: list[str] = field(default_factory=lambda: ["claude", "grok", "opencode"])
    raw: str = ""


def _unquote(s: str) -> str:
    s = s.strip()
    if len(s) >= 2 and s[0] == s[-1] and s[0] in "\"'":
        return s[1:-1]
    return s


def load_scenario(path: Path) -> Scenario:
    """Parse a constrained scenario.yml used by this harness.

    Supports:
      name: value
      purpose: >
        multiline
      unit_path: relative/path
      hard_invariants:
        - id
      observation_checklist:
        - id: foo
          expect: bar
      harnesses:
        - claude
    """
    text = path.read_text(encoding="utf-8")
    sc = Scenario(name=path.parent.name, raw=text)

    # name / unit_path one-liners
    if m := re.search(r"(?m)^name:\s*(.+)$", text):
        sc.name = _unquote(m.group(1))
    if m := re.search(r"(?m)^unit_path:\s*(.+)$", text):
        sc.unit_path = _unquote(m.group(1))

    # purpose: > block until next top-level key
    if m := re.search(
        r"(?ms)^purpose:\s*>\s*\n((?:[ \t]+.+\n?)+)",
        text,
    ):
        lines = [ln.strip() for ln in m.group(1).splitlines() if ln.strip()]
        sc.purpose = " ".join(lines)
    elif m := re.search(r"(?m)^purpose:\s*(.+)$", text):
        sc.purpose = _unquote(m.group(1))

    def _list_block(key: str) -> list[str]:
        """Lines under a top-level list key until the next top-level key."""
        m = re.search(
            rf"(?ms)^{re.escape(key)}:\s*\n(.*?)(?=^[a-zA-Z_][a-zA-Z0-9_]*:|\Z)",
            text,
        )
        if not m:
            return []
        out: list[str] = []
        for line in m.group(1).splitlines():
            lm = re.match(r"[ \t]*-[ \t]+([^:\s][^#]*?)\s*(?:#.*)?$", line)
            if lm:
                # plain list item: - name  (not - id: value)
                out.append(_unquote(lm.group(1).strip()))
        return out

    sc.hard_invariants = _list_block("hard_invariants")
    harnesses = _list_block("harnesses")
    if harnesses:
        sc.harnesses = harnesses

    # observation_checklist: nested id/expect maps
    if m := re.search(
        r"(?ms)^observation_checklist:\s*\n(.*?)(?=^[a-zA-Z_][a-zA-Z0-9_]*:|\Z)",
        text,
    ):
        block = m.group(1)
        current: dict[str, str] = {}
        for line in block.splitlines():
            if re.match(r"[ \t]*-[ \t]*id:", line):
                if current:
                    sc.observation_checklist.append(current)
                current = {"id": _unquote(line.split(":", 1)[1])}
            elif re.match(r"[ \t]+expect:", line):
                current["expect"] = _unquote(line.split(":", 1)[1])
            elif re.match(r"[ \t]+id:", line):
                current["id"] = _unquote(line.split(":", 1)[1])
        if current:
            sc.observation_checklist.append(current)

    if not sc.hard_invariants:
        raise ValueError(f"scenario missing hard_invariants: {path}")
    return sc
