"""Unit tests for the deterministic `generate` bookend.

Stdlib unittest (no external deps) so it runs out-of-the-box via
`python -m unittest`; also discovered by pytest if installed.
"""

import shutil
import subprocess
import tempfile
import unittest
from datetime import datetime
from pathlib import Path

from tests.swarm.harness.generate import GenerateError, generate

FIXED = datetime(2026, 5, 28, 12, 0, 0)


def _make_fake_repo(tmp: Path, *, with_seed=True, with_charter=True,
                    with_backlog=True, scenario_config=None) -> None:
    """Lay down a minimal fake repo root with one scenario + canonical roles."""
    scn = tmp / "tests" / "swarm" / "scenarios" / "demo"
    scn.mkdir(parents=True)
    if with_backlog:
        (scn / "backlog.md").write_text("# Backlog\n- item-1\n")
    if with_charter:
        (scn / "charter").mkdir()
        (scn / "charter" / "charter.md").write_text("# Charter\n")
    if with_seed:
        (scn / "seed").mkdir()
        (scn / "seed" / "app.py").write_text("print('hi')\n")
    if scenario_config is not None:
        (scn / "config.yml").write_text(scenario_config)
    roles = tmp / "src" / "swarm" / "roles"
    roles.mkdir(parents=True)
    (roles / "worker-contract.md").write_text("# canonical contract v1\n")
    (roles / "planner.md").write_text("# canonical planner v1\n")


class GenerateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)

    def test_builds_expected_tree(self):
        _make_fake_repo(self.tmp)
        run = generate("demo", root=self.tmp, now=FIXED)
        self.assertEqual(run.name, "demo-20260528-120000")
        self.assertTrue((run / "backlog.md").is_file())
        self.assertEqual((run / "app.py").read_text().strip(), "print('hi')")
        self.assertTrue((run / ".agent-tools/charter/charter.md").is_file())
        self.assertIn("schema_version: 1", (run / ".agent-tools/swarm/config.yml").read_text())
        self.assertIn("swarm/sessions/", (run / ".agent-tools/.gitignore").read_text())

    def test_copies_live_roles_verbatim(self):
        _make_fake_repo(self.tmp)
        run = generate("demo", root=self.tmp, now=FIXED)
        dest = run / ".agent-tools/swarm/roles"
        self.assertEqual((dest / "worker-contract.md").read_text(), "# canonical contract v1\n")
        self.assertEqual((dest / "planner.md").read_text(), "# canonical planner v1\n")

    def test_creates_main_branch_and_initial_commit(self):
        _make_fake_repo(self.tmp)
        run = generate("demo", root=self.tmp, now=FIXED)
        branch = subprocess.run(
            ["git", "branch", "--show-current"], cwd=run, capture_output=True, text=True
        ).stdout.strip()
        self.assertEqual(branch, "main")
        log = subprocess.run(
            ["git", "log", "--oneline"], cwd=run, capture_output=True, text=True
        ).stdout
        self.assertIn("seed demo scenario", log)

    def test_scenario_config_override(self):
        _make_fake_repo(self.tmp, scenario_config="schema_version: 1\ncustom: yes\n")
        run = generate("demo", root=self.tmp, now=FIXED)
        self.assertIn("custom: yes", (run / ".agent-tools/swarm/config.yml").read_text())

    def test_missing_scenario_raises(self):
        _make_fake_repo(self.tmp)
        with self.assertRaises(GenerateError):
            generate("nope", root=self.tmp, now=FIXED)

    def test_missing_backlog_raises(self):
        _make_fake_repo(self.tmp, with_backlog=False)
        with self.assertRaises(GenerateError):
            generate("demo", root=self.tmp, now=FIXED)

    def test_missing_charter_raises(self):
        _make_fake_repo(self.tmp, with_charter=False)
        with self.assertRaises(GenerateError):
            generate("demo", root=self.tmp, now=FIXED)

    def test_seedless_scenario_ok(self):
        _make_fake_repo(self.tmp, with_seed=False)
        run = generate("demo", root=self.tmp, now=FIXED)
        self.assertTrue((run / "backlog.md").is_file())


if __name__ == "__main__":
    unittest.main()
