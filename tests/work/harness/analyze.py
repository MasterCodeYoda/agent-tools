"""Analyze a workflow harness run (deterministic second bookend).

Checks hard invariants on unit session-state after an agent-driven
context-compact (or other workflow) session. Writes analysis.md + results.json.
"""

from __future__ import annotations

import json
import re
from dataclasses import asdict, dataclass, field
from pathlib import Path

from .scenario import Scenario, load_scenario


@dataclass
class CheckResult:
    id: str
    ok: bool
    detail: str


@dataclass
class Analysis:
    scenario: str
    run_dir: str
    unit_path: str
    hard: list[CheckResult] = field(default_factory=list)
    observations: list[CheckResult] = field(default_factory=list)
    passed: bool = False

    def to_dict(self) -> dict:
        return {
            "scenario": self.scenario,
            "run_dir": self.run_dir,
            "unit_path": self.unit_path,
            "passed": self.passed,
            "hard": [asdict(c) for c in self.hard],
            "observations": [asdict(c) for c in self.observations],
        }


class AnalyzeError(RuntimeError):
    pass


def _session_state_path(run_dir: Path, unit_path: str) -> Path:
    return run_dir / unit_path / "session-state.md"


def _latest_ic_block(text: str) -> str:
    """Return the last Intentional Compaction section body (heading → next ###/## or EOF)."""
    matches = list(
        re.finditer(
            r"(?im)^#{2,3}\s+Intentional Compaction[^\n]*\n",
            text,
        )
    )
    if not matches:
        # bare section title used in templates
        matches = list(
            re.finditer(r"(?im)^##\s+Intentional Compaction\s*\n", text)
        )
    if not matches:
        return ""
    start = matches[-1].end()
    rest = text[start:]
    nxt = re.search(r"(?m)^#{2,3}\s+\S", rest)
    return rest[: nxt.start()] if nxt else rest


def _has_field(block: str, name: str) -> bool:
    return bool(
        re.search(rf"(?im)^\s*[-*]?\s*\*?\*?{re.escape(name)}\*?\*?\s*:", block)
        or re.search(rf"(?im)\*\*{re.escape(name)}\*\*\s*:", block)
    )


def check_invariant(inv: str, run_dir: Path, unit_path: str, ss_text: str) -> CheckResult:
    block = _latest_ic_block(ss_text)
    ss_path = _session_state_path(run_dir, unit_path)

    if inv == "session_state_exists":
        ok = ss_path.is_file()
        return CheckResult(inv, ok, str(ss_path) if ok else "missing session-state.md")

    if inv == "ic_heading_present":
        ok = bool(block) or bool(
            re.search(r"(?im)Intentional Compaction", ss_text)
        )
        # require a non-empty body under the heading if heading exists
        if re.search(r"(?im)Intentional Compaction", ss_text) and not block.strip():
            # heading only with placeholder still fails if too short
            ok = "Goal" in ss_text or "compact_focus" in ss_text
        detail = "latest IC block found" if ok else "no Intentional Compaction section with body"
        return CheckResult(inv, ok, detail)

    if inv == "ic_has_goal_or_next":
        ok = bool(
            re.search(r"(?im)(Goal|next step|NEXT|Current failure)", block or ss_text)
        )
        return CheckResult(inv, ok, "goal/next language present" if ok else "missing goal/next")

    if inv == "compact_focus_present":
        ok = _has_field(block or ss_text, "compact_focus")
        return CheckResult(
            inv, ok, "compact_focus field present" if ok else "compact_focus missing"
        )

    if inv == "resume_loads_present":
        ok = _has_field(block or ss_text, "resume_loads")
        return CheckResult(
            inv, ok, "resume_loads field present" if ok else "resume_loads missing"
        )

    if inv == "resume_loads_unit_relative":
        # every resume path should stay under the unit or planning root — no absolute host paths required
        # fail if we see obvious product/repo escape patterns
        blob = block or ss_text
        bad = re.findall(
            r"(?i)(/Users/|/home/|[A-Z]:\\|/tmp/agent-tools-consumer)",
            blob,
        )
        ok = not bad
        return CheckResult(
            inv,
            ok,
            "resume_loads look workspace-relative" if ok else f"suspicious absolute paths: {bad}",
        )

    if inv == "no_product_leak_names":
        # Keep harness generic: flag known personal product names if they appear in IC
        forbidden = ("Spectral", "ZzzAPI", "SPEC-", "DAY-")
        hits = [f for f in forbidden if f in (block or ss_text)]
        # SPEC- and DAY- might be too aggressive for generic text — only flag if in IC block
        hits = [f for f in forbidden if f in block] if block else []
        ok = not hits
        return CheckResult(
            inv, ok, "no product leak names" if ok else f"found: {hits}"
        )

    if inv == "drive_completed_marker":
        # Optional: agent may write .harness-meta/drive-complete after soft stop
        marker = run_dir / ".harness-meta" / "drive-complete"
        # Not required for pass of protocol — soft check only if listed as hard
        ok = marker.is_file() or bool(block)
        return CheckResult(
            inv,
            ok,
            "IC present (drive-complete marker optional)" if ok else "no IC and no marker",
        )

    return CheckResult(inv, False, f"unknown invariant id: {inv}")


def check_observation(item: dict[str, str], ss_text: str) -> CheckResult:
    oid = item.get("id", "obs")
    expect = item.get("expect", "")
    # Soft: keyword presence in session-state
    tokens = [t for t in re.split(r"\W+", expect.lower()) if len(t) > 4][:5]
    blob = ss_text.lower()
    hits = sum(1 for t in tokens if t in blob)
    ok = hits >= max(1, len(tokens) // 2) if tokens else True
    return CheckResult(
        oid,
        ok,
        f"expect~{expect!r} soft-match hits={hits}/{len(tokens)}",
    )


def analyze(run_dir: Path, *, scenario: Scenario | None = None) -> Analysis:
    run_dir = run_dir.resolve()
    if not run_dir.is_dir():
        raise AnalyzeError(f"run dir not found: {run_dir}")

    yml = run_dir / "scenario.yml"
    if not yml.is_file():
        # fall back to meta + parent scenarios (older runs)
        meta = run_dir / ".harness-meta" / "scenario"
        if meta.is_file():
            name = meta.read_text(encoding="utf-8").strip()
            root = Path(__file__).resolve().parents[3]
            yml = root / "tests" / "workflow" / "scenarios" / name / "scenario.yml"
        else:
            raise AnalyzeError("no scenario.yml in run dir")

    sc = scenario or load_scenario(yml)
    unit_path = sc.unit_path
    meta_unit = run_dir / ".harness-meta" / "unit_path"
    if meta_unit.is_file():
        unit_path = meta_unit.read_text(encoding="utf-8").strip() or unit_path

    ss_path = _session_state_path(run_dir, unit_path)
    ss_text = ss_path.read_text(encoding="utf-8") if ss_path.is_file() else ""

    result = Analysis(
        scenario=sc.name,
        run_dir=str(run_dir),
        unit_path=unit_path,
    )

    for inv in sc.hard_invariants:
        result.hard.append(check_invariant(inv, run_dir, unit_path, ss_text))

    for obs in sc.observation_checklist:
        result.observations.append(check_observation(obs, ss_text))

    result.passed = all(c.ok for c in result.hard)
    return result


def write_analysis(run_dir: Path, analysis: Analysis) -> tuple[Path, Path]:
    md_path = run_dir / "analysis.md"
    json_path = run_dir / "results.json"

    lines = [
        f"# Workflow harness analysis — {analysis.scenario}",
        "",
        f"- **Run:** `{analysis.run_dir}`",
        f"- **Unit:** `{analysis.unit_path}`",
        f"- **Hard invariants:** `{'PASS' if analysis.passed else 'FAIL'}`",
        "",
        "## Hard invariants",
        "",
        "| ID | Result | Detail |",
        "|----|--------|--------|",
    ]
    for c in analysis.hard:
        mark = "PASS" if c.ok else "FAIL"
        lines.append(f"| `{c.id}` | **{mark}** | {c.detail} |")

    if analysis.observations:
        lines += ["", "## Observation checklist (soft)", "", "| ID | Result | Detail |",
                  "|----|--------|--------|"]
        for c in analysis.observations:
            mark = "ok" if c.ok else "weak"
            lines.append(f"| `{c.id}` | {mark} | {c.detail} |")

    lines += [
        "",
        "## Next",
        "",
        "- PASS: record harness + date; optional copy to `tests/work/history/` if noteworthy.",
        "- FAIL: inspect unit `session-state.md`; re-run with a **fresh** `new-run.sh` after fixes.",
        "",
    ]
    md_path.write_text("\n".join(lines), encoding="utf-8")
    json_path.write_text(json.dumps(analysis.to_dict(), indent=2) + "\n", encoding="utf-8")
    return md_path, json_path
