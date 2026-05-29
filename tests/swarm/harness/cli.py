"""CLI dispatch for the swarm test harness.

    python -m tests.swarm.harness generate <scenario>
    python -m tests.swarm.harness ingest <run-dir>
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


def _cmd_generate(args: argparse.Namespace) -> int:
    from .generate import GenerateError, format_next_step, generate

    try:
        run_dir = generate(args.scenario)
    except GenerateError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print(format_next_step(run_dir))
    return 0


def _cmd_ingest(args: argparse.Namespace) -> int:
    from .ingest import ingest, write_observations

    run_dir = Path(args.run_dir)
    observations = ingest(run_dir)
    out_path = write_observations(run_dir, observations)
    print(f"Wrote {out_path}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="python -m tests.swarm.harness",
        description="Deterministic bookends for the /swarm test harness.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    g = sub.add_parser("generate", help="Build a throwaway repo from a scenario.")
    g.add_argument("scenario", help="Scenario name under tests/swarm/scenarios/.")
    g.set_defaults(func=_cmd_generate)

    i = sub.add_parser("ingest", help="Summarize a run's session logs to observations.json.")
    i.add_argument("run_dir", help="Path to a generated run directory.")
    i.set_defaults(func=_cmd_ingest)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)
