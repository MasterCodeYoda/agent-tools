"""Unit tests for workflow harness analyze (no agent)."""

from __future__ import annotations

from pathlib import Path

import pytest

from tests.workflow.harness.analyze import analyze, check_invariant, write_analysis
from tests.workflow.harness.generate import generate
from tests.workflow.harness.scenario import load_scenario


FIX = Path(__file__).resolve().parent / "fixtures"


def test_load_scenario_context_compact_soft():
    root = Path(__file__).resolve().parents[4]
    sc = load_scenario(
        root / "tests/workflow/scenarios/context-compact-soft/scenario.yml"
    )
    assert sc.name == "context-compact-soft"
    assert "compact_focus_present" in sc.hard_invariants
    assert sc.unit_path.endswith("smoke-unit")


def test_generate_and_pre_agent_analyze_fails(tmp_path: Path):
    root = Path(__file__).resolve().parents[4]
    run_dir = generate(
        "context-compact-soft",
        root=root,
        runs_root=tmp_path / "runs",
    )
    assert (run_dir / "DRIVE.md").is_file()
    assert (run_dir / ".agent-tools/planning/smoke-unit/session-state.md").is_file()
    result = analyze(run_dir)
    # Seed has no IC with compact_focus — hard invariants should fail until agent runs
    assert result.passed is False
    assert any(c.id == "compact_focus_present" and not c.ok for c in result.hard)


def test_analyze_passes_with_full_ic(tmp_path: Path):
    root = Path(__file__).resolve().parents[4]
    run_dir = generate(
        "context-compact-soft",
        root=root,
        runs_root=tmp_path / "runs",
    )
    ss = run_dir / ".agent-tools/planning/smoke-unit/session-state.md"
    ss.write_text(
        ss.read_text(encoding="utf-8")
        + """

### Intentional Compaction — 2026-07-23 (harness test)

- **Goal:** validate context-compact soft path
- **Approach:** write IC then soft stop
- **Done so far:** task 1 only
- **Current failure or next step:** resume at clamp helper after reclaim
- **Key files:** src/counter.py
- **Tests / verification last green:** python -m src.counter
- **Do not re-open:** implementing tasks 2-4 in this session
- **compact_focus:** smoke-unit mid-phase; next is clamp(); branch feat/smoke; do not implement now
- **resume_loads:**
  1. .agent-tools/planning/smoke-unit/session-state.md
  2. .agent-tools/planning/smoke-unit/implementation-plan.md
  3. .agent-tools/planning/smoke-unit/codebase-research.md
""",
        encoding="utf-8",
    )
    result = analyze(run_dir)
    assert result.passed, [c for c in result.hard if not c.ok]
    md, js = write_analysis(run_dir, result)
    assert md.is_file() and js.is_file()


def test_ic_block_field_detection():
    block = """
- **Goal:** x
- **compact_focus:** keep the clamp next step
- **resume_loads:**
  1. a.md
"""
    assert check_invariant(
        "compact_focus_present", Path("."), "u", "## Intentional Compaction\n" + block
    ).ok
