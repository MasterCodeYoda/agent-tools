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


_KNOWN_ROLES = {"planner", "implementer", "reviewer", "conflict-resolver", "integration-fixer"}
_KNOWN_STATUSES = {
    "DONE", "DONE_WITH_CONCERNS", "NEEDS_CONTEXT", "BLOCKED",
    "APPROVED", "FIX_REQUESTED", "FAILED",
}
# description verb -> role, for transcripts where the dispatch is a generic agent
_DESC_ROLE = [
    ("plan", "planner"), ("implement", "implementer"), ("review", "reviewer"),
    ("resolve", "conflict-resolver"), ("conflict", "conflict-resolver"),
    ("integration", "integration-fixer"),
]


def _project_dir(run_dir: Path) -> Path | None:
    """The ``~/.claude/projects`` dir for this run's cwd, if present.

    Claude Code names that dir after the cwd with every non-alphanumeric char (slashes, dots,
    etc.) collapsed to ``-``.
    """
    proj = Path.home() / ".claude" / "projects"
    if not proj.is_dir():
        return None
    pdir = proj / re.sub(r"[^A-Za-z0-9]", "-", str(run_dir.resolve()))
    return pdir if pdir.is_dir() else None


def _find_transcript(run_dir: Path) -> Path | None:
    """Locate the orchestrator transcript for this run dir, if present.

    The orchestrator session is the one whose ``tool_result`` blocks carry the workers'
    structured returns; we pick the project transcript that yields the most of them. Reviewer
    sub-sessions and worker sidechains carry none, so they self-exclude.
    """
    pdir = _project_dir(run_dir)
    if pdir is None:
        return None
    best, best_n = None, 0
    for p in sorted(pdir.glob("*.jsonl")):
        if not p.is_file():
            continue
        n = len(transcript_dispatches(p))
        if n > best_n:
            best, best_n = p, n
    return best


def _parse_swarm_return(text: str) -> dict | None:
    """If ``text`` contains a swarm structured return, extract {role, status, item}."""
    if not text:
        return None
    role = re.search(r"^\s*role:\s*([\w-]+)", text, re.MULTILINE)
    status = re.search(r"^\s*status:\s*([\w]+)", text, re.MULTILINE)
    item = re.search(r"^\s*item:\s*([^\s#]+)", text, re.MULTILINE)
    if not (role and status):
        return None
    r = role.group(1)
    s = status.group(1)
    if r not in _KNOWN_ROLES or s not in _KNOWN_STATUSES:
        return None
    return {"role": r, "status": s, "item": item.group(1).strip("'\"") if item else "unknown"}


def _result_text(block: dict) -> str:
    content = block.get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(p.get("text", "") for p in content if isinstance(p, dict))
    return ""


def transcript_dispatches(transcript: Path) -> list[dict]:
    """Recover {role, status, item} per dispatch from an orchestrator transcript.

    Workers return their structured YAML to the orchestrator via the Task tool; that return
    lands in a ``tool_result`` block in the transcript. We pair each result to its dispatch by
    ``tool_use_id`` and parse the swarm return out of it.
    """
    desc_by_id: dict[str, str] = {}
    out: list[dict] = []
    for line in transcript.open(encoding="utf-8", errors="replace"):
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        msg = obj.get("message")
        content = msg.get("content") if isinstance(msg, dict) else None
        if not isinstance(content, list):
            continue
        for block in content:
            if not isinstance(block, dict):
                continue
            btype = block.get("type")
            if btype == "tool_use" and block.get("name") in ("Task", "Agent"):
                inp = block.get("input") or {}
                desc_by_id[block.get("id", "")] = str(inp.get("description") or "")
            elif btype == "tool_result":
                ret = _parse_swarm_return(_result_text(block))
                if ret is None:
                    continue
                if ret["role"] == "unknown" or ret["role"] not in _KNOWN_ROLES:
                    desc = desc_by_id.get(block.get("tool_use_id", ""), "").lower()
                    for needle, role in _DESC_ROLE:
                        if needle in desc:
                            ret["role"] = role
                            break
                out.append(ret)
    return out


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
        "transcript_source": None,
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

    # Fallback: if no on-disk log carried a parseable return, the structured returns live only
    # in the orchestrator's Claude Code transcript. Recover dispatch counts from there.
    if obs["dispatch_count"] == 0:
        transcript = _find_transcript(run_dir)
        if transcript is not None:
            dispatches = transcript_dispatches(transcript)
            if dispatches:
                obs["transcript_source"] = str(transcript)
                obs["warnings"].append(
                    f"session logs carried no parseable returns; "
                    f"recovered {len(dispatches)} dispatch(es) from transcript {transcript.name}"
                )
                for d in dispatches:
                    role, status, item = d["role"], d["status"], d["item"]
                    obs["dispatch_count"] += 1
                    by_role[role]["dispatches"] += 1
                    by_role[role]["statuses"][status] += 1
                    obs["status_tally"][status] += 1
                    if role not in items[item]["roles_seen"]:
                        items[item]["roles_seen"].append(role)
                    items[item]["last_status"] = status

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
