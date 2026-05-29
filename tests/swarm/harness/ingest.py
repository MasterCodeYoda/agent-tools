"""Summarize a /swarm run's session logs into structured observations (deterministic).

Second bookend of the harness. Walks the generated repo's
`.agent-tools/swarm/sessions/<run-id>/<item>/<role>-<n>.md` logs and emits an
`observations.json` the `swarm:test` skill reasons over.

Dependency-free: PyYAML is intentionally NOT required. The authoritative
`status`/`role`/`item` live in each log's flat frontmatter; for the worker's
returned YAML block we only need presence/parseability, size, and the
`files_changed` list — all extracted with targeted stdlib parsing.
"""

from __future__ import annotations

import json
import re
import subprocess
from collections import defaultdict
from pathlib import Path

_FENCE_RE = re.compile(r"```ya?ml\s*\n(.*?)\n```", re.DOTALL | re.IGNORECASE)


def parse_frontmatter(text: str) -> dict[str, str]:
    """Parse leading `--- ... ---` flat key:value frontmatter. Returns {} if absent."""
    if not text.startswith("---"):
        return {}
    end = text.find("\n---", 3)
    if end == -1:
        return {}
    block = text[3:end].strip("\n")
    out: dict[str, str] = {}
    for line in block.splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if ":" not in line:
            continue
        key, _, val = line.partition(":")
        out[key.strip()] = val.strip().strip("'\"")
    return out


def _section(text: str, heading: str) -> str:
    """Return the body under a `## <heading>` section up to the next `## ` heading."""
    pat = re.compile(rf"^##\s+{re.escape(heading)}.*?$", re.MULTILINE)
    m = pat.search(text)
    if not m:
        return ""
    start = m.end()
    nxt = re.search(r"^##\s+", text[start:], re.MULTILINE)
    return text[start: start + nxt.start()] if nxt else text[start:]


def extract_return_block(text: str) -> str | None:
    """The fenced YAML under the '## Return' section, or None if absent."""
    section = _section(text, "Return")
    if not section:
        # Some logs may put the return without the heading; fall back to last fence.
        fences = _FENCE_RE.findall(text)
        return fences[-1] if fences else None
    m = _FENCE_RE.search(section)
    return m.group(1) if m else None


def extract_files_changed(return_block: str) -> list[str]:
    """Best-effort extraction of artifacts.files_changed (inline or block list)."""
    if not return_block:
        return []
    # inline form:  files_changed: [a, b]
    m = re.search(r"files_changed:\s*\[(.*?)\]", return_block)
    if m:
        return [p.strip().strip("'\"") for p in m.group(1).split(",") if p.strip()]
    # block form:
    #   files_changed:
    #     - a
    #     - b
    lines = return_block.splitlines()
    out: list[str] = []
    for i, line in enumerate(lines):
        if re.match(r"\s*files_changed:\s*$", line):
            indent = len(line) - len(line.lstrip())
            for nxt in lines[i + 1:]:
                if not nxt.strip():
                    continue
                nxt_indent = len(nxt) - len(nxt.lstrip())
                if nxt_indent <= indent or not nxt.lstrip().startswith("-"):
                    break
                out.append(nxt.lstrip()[1:].strip().strip("'\""))
            break
    return out


def _is_out_of_scope(path: str) -> bool:
    """Heuristic: a worker should write relative paths within its own worktree."""
    return path.startswith("/") or ".." in Path(path).parts


def _git_remotes(run_dir: Path) -> list[str]:
    try:
        res = subprocess.run(
            ["git", "remote"], cwd=run_dir, capture_output=True, text=True, check=True
        )
        return [r for r in res.stdout.split() if r]
    except (subprocess.CalledProcessError, FileNotFoundError, NotADirectoryError):
        return []


def _sessions_root(run_dir: Path) -> Path | None:
    sess = run_dir / ".agent-tools" / "swarm" / "sessions"
    if not sess.is_dir():
        return None
    runs = [d for d in sorted(sess.iterdir()) if d.is_dir()]
    return runs[0] if runs else None


def ingest(run_dir: Path) -> dict:
    """Walk a run's session logs and return a structured observations dict."""
    run_dir = Path(run_dir)
    obs: dict = {
        "run_dir": str(run_dir),
        "run_id": None,
        "dispatch_count": 0,
        "by_role": {},
        "status_tally": defaultdict(int),
        "malformed_returns": [],
        "return_sizes": [],
        "missing_decision_logs": [],
        "items": {},
        "safety": {"remotes": _git_remotes(run_dir), "push_mentions": [], "out_of_scope_writes": []},
        "warnings": [],
    }

    sess_root = _sessions_root(run_dir)
    if sess_root is None:
        obs["warnings"].append("no sessions found (run may not have happened yet)")
        obs["status_tally"] = dict(obs["status_tally"])
        return obs
    obs["run_id"] = sess_root.name

    by_role: dict[str, dict] = defaultdict(lambda: {"dispatches": 0, "statuses": defaultdict(int)})
    items: dict[str, dict] = defaultdict(lambda: {"roles_seen": [], "last_status": None})

    log_files = sorted(p for p in sess_root.rglob("*.md") if p.is_file())
    for path in log_files:
        rel = str(path.relative_to(run_dir))
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as exc:
            obs["warnings"].append(f"could not read {rel}: {exc}")
            continue

        fm = parse_frontmatter(text)
        if not fm or "role" not in fm:
            obs["malformed_returns"].append({"file": rel, "reason": "missing/!malformed frontmatter"})
            continue

        role = fm.get("role", "unknown")
        status = fm.get("status", "UNKNOWN")
        item = fm.get("item", "unknown")

        obs["dispatch_count"] += 1
        by_role[role]["dispatches"] += 1
        by_role[role]["statuses"][status] += 1
        obs["status_tally"][status] += 1
        if role not in items[item]["roles_seen"]:
            items[item]["roles_seen"].append(role)
        items[item]["last_status"] = status

        ret = extract_return_block(text)
        if ret is None or "status:" not in ret:
            obs["malformed_returns"].append({"file": rel, "reason": "no parseable return block"})
        else:
            obs["return_sizes"].append(
                {"file": rel, "role": role, "chars": len(ret), "lines": ret.count("\n") + 1}
            )
            for fc in extract_files_changed(ret):
                if _is_out_of_scope(fc):
                    obs["safety"]["out_of_scope_writes"].append(
                        {"file": rel, "item": item, "path": fc}
                    )

        if not _section(text, "Decision log").strip():
            obs["missing_decision_logs"].append(rel)

        if re.search(r"git\s+push|\bpush to (origin|remote)", text, re.IGNORECASE):
            obs["safety"]["push_mentions"].append({"file": rel})

    # finalize (convert defaultdicts to plain dicts for JSON)
    obs["by_role"] = {
        r: {"dispatches": d["dispatches"], "statuses": dict(d["statuses"])}
        for r, d in by_role.items()
    }
    obs["items"] = {k: v for k, v in items.items()}
    obs["status_tally"] = dict(obs["status_tally"])
    return obs


def write_observations(run_dir: Path, observations: dict) -> Path:
    out_path = Path(run_dir) / "observations.json"
    out_path.write_text(json.dumps(observations, indent=2) + "\n")
    return out_path
