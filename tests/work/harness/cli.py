"""CLI for the workflow process test harness.

    python -m tests.work.harness generate <scenario>
    python -m tests.work.harness analyze <run-dir>
    python -m tests.work.harness list
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def _scenarios_dir() -> Path:
    return Path(__file__).resolve().parents[1] / "scenarios"


def _cmd_list(_: argparse.Namespace) -> int:
    root = _scenarios_dir()
    print("scenarios:")
    if not root.is_dir():
        return 0
    for d in sorted(root.iterdir()):
        if d.is_dir() and (d / "scenario.yml").is_file():
            print(f"  - {d.name}")
    return 0


def _cmd_generate(args: argparse.Namespace) -> int:
    from .generate import GenerateError, format_next_step, generate

    try:
        run_dir = generate(args.scenario)
    except GenerateError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print(format_next_step(run_dir))
    return 0


def _cmd_analyze(args: argparse.Namespace) -> int:
    from .analyze import AnalyzeError, analyze, write_analysis

    run_dir = Path(args.run_dir)
    try:
        result = analyze(run_dir)
    except AnalyzeError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    md_path, json_path = write_analysis(run_dir, result)
    status = "PASS" if result.passed else "FAIL"
    print(f"Hard invariants: {status}")
    for c in result.hard:
        mark = "ok" if c.ok else "FAIL"
        print(f"  [{mark}] {c.id}: {c.detail}")
    print(f"Wrote {md_path}")
    print(f"Wrote {json_path}")
    return 0 if result.passed else 2


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="python -m tests.work.harness",
        description="Deterministic bookends for workflow process scenarios.",
    )
    sub = p.add_subparsers(dest="command", required=True)

    ls = sub.add_parser("list", help="List scenarios.")
    ls.set_defaults(func=_cmd_list)

    g = sub.add_parser("generate", help="Build a throwaway repo from a scenario.")
    g.add_argument("scenario", help="Name under tests/work/scenarios/.")
    g.set_defaults(func=_cmd_generate)

    a = sub.add_parser("analyze", help="Check hard invariants on a finished run.")
    a.add_argument("run_dir", help="Path to a generated run directory.")
    a.set_defaults(func=_cmd_analyze)

    return p


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)
