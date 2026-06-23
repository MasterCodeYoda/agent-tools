"""Build a throwaway git repo from a scenario definition (deterministic).

This is the first bookend of the harness. It lays down the scenario's seed
sources, charter, swarm config, the *current* canonical role templates, and the
backlog, then initialises a real git repo with a `main` branch and an initial
commit — leaving a project that is ready for an agent to run `/swarm backlog.md`
against.

Dependency-free (stdlib only). Pure file/git operations; no YAML parsing.
"""

from __future__ import annotations

import shutil
import subprocess
from datetime import datetime
from pathlib import Path

# A sensible default swarm config written when a scenario doesn't ship its own.
DEFAULT_CONFIG_YML = """\
schema_version: 1
concurrency_cap: 5
role_chain:
  - planner
  - implementer
  - reviewer
models:
  planner: most_capable
  implementer: mid_tier
  reviewer: most_capable
  conflict_resolver: most_capable
  integration_fixer: most_capable
clis:
  planner: claude
  implementer: claude
  reviewer: claude
  conflict_resolver: claude
  integration_fixer: claude
test_command: pytest -q
backlog:
  default_source: file
  default_filter: null
sessions:
  retention_days: null
pre_launch:
  always_confirm: true
output:
  per_wave_summary: brief
"""

UMBRELLA_GITIGNORE = """\
# Managed by Agent Tools. User edits respected on re-run.
swarm/active-run
swarm/sessions/
"""


class GenerateError(RuntimeError):
    """Raised when a scenario is missing or malformed."""


def repo_root() -> Path:
    """The agent-tools repo root (three levels up from this file)."""
    return Path(__file__).resolve().parents[3]


def _git(args: list[str], cwd: Path) -> None:
    subprocess.run(["git", *args], cwd=cwd, check=True,
                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True)


def generate(
    scenario: str,
    *,
    root: Path | None = None,
    runs_root: Path | None = None,
    now: datetime | None = None,
) -> Path:
    """Generate a throwaway repo for `scenario` and return its path.

    Args injectable for tests: `root` (repo root), `runs_root` (where run dirs
    go), and `now` (timestamp source).
    """
    root = root or repo_root()
    runs_root = runs_root or (root / "tests" / "swarm" / "runs")
    now = now or datetime.now()

    scenario_dir = root / "tests" / "swarm" / "scenarios" / scenario
    if not scenario_dir.is_dir():
        raise GenerateError(f"Scenario not found: {scenario_dir}")
    backlog_src = scenario_dir / "backlog.md"
    if not backlog_src.is_file():
        raise GenerateError(f"Scenario missing backlog.md: {backlog_src}")

    # Bootstrap mode is keyed on whether the scenario ships a charter:
    #   charter/ present  → SEEDED: generate writes the full .agent-tools/ umbrella.
    #   charter/ absent   → INIT-FIRST: bare repo; the run begins with /swarm:init, which
    #                       authors the charter + umbrella + roles itself.
    charter_src = scenario_dir / "charter"
    seeded = charter_src.is_dir()

    roles_src = root / "src" / "swarm" / "roles"
    if seeded and not roles_src.is_dir():
        raise GenerateError(f"Canonical roles not found: {roles_src}")

    stamp = now.strftime("%Y%m%d-%H%M%S")
    run_dir = runs_root / f"{scenario}-{stamp}"
    if run_dir.exists():
        raise GenerateError(f"Run dir already exists: {run_dir}")
    run_dir.mkdir(parents=True)

    # 1. Seed application sources at the repo root (optional dir).
    #    Skip Python bytecode caches so generated repos stay clean.
    _ignore = shutil.ignore_patterns("__pycache__", "*.pyc", ".pytest_cache")
    seed_src = scenario_dir / "seed"
    if seed_src.is_dir():
        for item in sorted(seed_src.iterdir()):
            if item.name in ("__pycache__", ".pytest_cache") or item.suffix == ".pyc":
                continue
            dest = run_dir / item.name
            if item.is_dir():
                shutil.copytree(item, dest, ignore=_ignore)
            else:
                shutil.copy2(item, dest)

    # 2. Backlog at the repo root.
    shutil.copy2(backlog_src, run_dir / "backlog.md")

    # 3. .agent-tools umbrella — only in SEEDED mode. In init-first mode the repo is left
    #    bare; /swarm:init authors the umbrella when the run begins.
    if seeded:
        agent_tools = run_dir / ".agent-tools"
        shutil.copytree(charter_src, agent_tools / "charter")
        swarm_dir = agent_tools / "swarm"
        swarm_dir.mkdir(parents=True)
        config_src = scenario_dir / "config.yml"
        if config_src.is_file():
            shutil.copy2(config_src, swarm_dir / "config.yml")
        else:
            (swarm_dir / "config.yml").write_text(DEFAULT_CONFIG_YML)
        shutil.copytree(roles_src, swarm_dir / "roles")
        (agent_tools / ".gitignore").write_text(UMBRELLA_GITIGNORE)

    # 4. Real git repo with a `main` branch + initial commit.
    _git(["-c", "init.defaultBranch=main", "init"], cwd=run_dir)
    _git(["add", "-A"], cwd=run_dir)
    _git(
        ["-c", "user.name=swarm-harness", "-c", "user.email=harness@local",
         "commit", "-m", f"chore: seed {scenario} scenario"],
        cwd=run_dir,
    )

    return run_dir


def format_next_step(run_dir: Path) -> str:
    init_first = not (run_dir / ".agent-tools" / "charter").is_dir()
    run_steps = f"  cd {run_dir}\n"
    if init_first:
        run_steps += (
            "  /swarm:init          # bare repo: author the charter + umbrella first\n"
            "  /swarm backlog.md\n"
        )
    else:
        run_steps += "  /swarm backlog.md\n"
    return (
        f"Generated: {run_dir}\n\n"
        f"Next: run from the generated repo:\n"
        f"{run_steps}\n"
        f"Then analyze the run:\n"
        f"  /swarm:test {run_dir}\n"
    )
