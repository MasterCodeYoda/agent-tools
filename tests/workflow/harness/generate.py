"""Build a throwaway git repo from a workflow scenario (deterministic).

First bookend: seed sources + planning unit, init git, write DRIVE.md with the
agent handoff. The middle step (agent runs context-compact / workflow skills)
is not automated.
"""

from __future__ import annotations

import shutil
import subprocess
from datetime import datetime
from pathlib import Path

from .scenario import load_scenario


class GenerateError(RuntimeError):
    pass


def repo_root() -> Path:
    return Path(__file__).resolve().parents[3]


def _git(args: list[str], cwd: Path) -> None:
    subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.PIPE,
        text=True,
    )


def generate(
    scenario: str,
    *,
    root: Path | None = None,
    runs_root: Path | None = None,
    now: datetime | None = None,
) -> Path:
    root = root or repo_root()
    runs_root = runs_root or (root / "tests" / "workflow" / "runs")
    now = now or datetime.now()

    scenario_dir = root / "tests" / "workflow" / "scenarios" / scenario
    if not scenario_dir.is_dir():
        raise GenerateError(f"Scenario not found: {scenario_dir}")

    seed_src = scenario_dir / "seed"
    if not seed_src.is_dir():
        raise GenerateError(f"Scenario missing seed/: {seed_src}")

    sc = load_scenario(scenario_dir / "scenario.yml")

    stamp = now.strftime("%Y%m%d-%H%M%S")
    run_dir = runs_root / f"{scenario}-{stamp}"
    if run_dir.exists():
        raise GenerateError(f"Run dir already exists: {run_dir}")
    run_dir.mkdir(parents=True)

    ignore = shutil.ignore_patterns("__pycache__", "*.pyc", ".pytest_cache", ".git")
    for item in sorted(seed_src.iterdir()):
        dest = run_dir / item.name
        if item.is_dir():
            shutil.copytree(item, dest, ignore=ignore)
        else:
            shutil.copy2(item, dest)

    # Scenario metadata for analyze (copy, not symlink — run is self-contained)
    shutil.copy2(scenario_dir / "scenario.yml", run_dir / "scenario.yml")
    (run_dir / ".harness-meta").mkdir(exist_ok=True)
    (run_dir / ".harness-meta" / "scenario").write_text(scenario + "\n", encoding="utf-8")
    (run_dir / ".harness-meta" / "unit_path").write_text(
        sc.unit_path + "\n", encoding="utf-8"
    )

    prompts_src = scenario_dir / "prompts"
    if prompts_src.is_dir():
        prompts_dest = run_dir / "prompts"
        prompts_dest.mkdir(exist_ok=True)
        for p in sorted(prompts_src.iterdir()):
            if p.is_file():
                shutil.copy2(p, prompts_dest / p.name)

    drive = _build_drive_md(run_dir, scenario, sc)
    (run_dir / "DRIVE.md").write_text(drive, encoding="utf-8")

    _git(["init", "-b", "main"], run_dir)
    _git(["config", "user.email", "workflow-harness@local"], run_dir)
    _git(["config", "user.name", "workflow-harness"], run_dir)
    _git(["add", "-A"], run_dir)
    _git(["commit", "-m", f"test: seed {scenario} harness run"], run_dir)

    return run_dir


def _build_drive_md(run_dir: Path, scenario: str, sc) -> str:
    prompt_path = run_dir / "prompts" / "drive.md"
    body = ""
    if prompt_path.is_file():
        body = prompt_path.read_text(encoding="utf-8").strip() + "\n\n"

    harnesses = ", ".join(sc.harnesses) if sc.harnesses else "claude, grok, opencode"
    return f"""# Workflow harness — agent drive step

**Scenario:** `{scenario}`  
**Run dir:** `{run_dir}`  
**Unit:** `{sc.unit_path}`  
**Primary harnesses:** {harnesses}

This file is the **non-automated middle bookend**. Deterministic tools cannot run the
agent skill; you (or an agent session) must.

## You must

1. `cd` into this run directory (cwd matters for planning-root resolution).
2. Open a **new** agent session in Claude Code, Grok Build, or OpenCode.
3. Confirm workflow skills are current (`./setup.sh` in agent-tools if needed).
4. Paste the drive prompt below (or load `prompts/drive.md`).
5. When the agent stops (Resume card or compact complete), return here and run analyze:

```bash
# from agent-tools repo root
python -m tests.workflow.harness analyze "{run_dir}"
```

## Drive prompt

{body if body else "_(missing prompts/drive.md)_"}

## After analyze

- Exit code 0 + `analysis.md` hard invariants PASS → scenario green for that harness.
- Failures → fix protocol or seed; re-generate a fresh run (do not reuse a polluted tree).
"""


def format_next_step(run_dir: Path) -> str:
    return f"""Generated workflow harness run:

  {run_dir}

Next (not automated):

  1. cd "{run_dir}"
  2. Open Claude Code / Grok Build / OpenCode in that directory
  3. Follow DRIVE.md (paste prompts/drive.md)
  4. When the agent finishes the compact protocol:

       python -m tests.workflow.harness analyze "{run_dir}"

  Re-read DRIVE.md inside the run dir for the full prompt.
"""
