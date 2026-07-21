"""Golden-file regression tests for tools/publish-skills.sh.

Runs the real publisher against the fixture tree in fixtures/src/ (via the
AGENT_TOOLS_SRC_ROOT / AGENT_TOOLS_DIST_ROOT overrides) and compares the
output byte-for-byte against the committed expected/ trees.

Covered behaviors, one fixture each:
  - agent:include / agent:exclude markup resolution per agent
  - stripping of plain HTML comments from .md files
  - non-.md assets copied verbatim (markup untouched)
  - pdf-build/ skip
  - colon-named sub-skill flattening (claude/grok/factory only)
  - Codex nested-only layout (no flattened siblings)
  - OpenCode commands/ emission: colon sub-skills, bare family roots
    (e.g. /workflow when family has colon children), leaf-as-command removal
    from skills/

Stdlib unittest (no external deps) so it runs out-of-the-box via
`python -m unittest`; also discovered by pytest if installed.

To regenerate goldens after an intentional publisher change:
  rm -rf tests/publisher/expected
  AGENT_TOOLS_SRC_ROOT=$PWD/tests/publisher/fixtures/src \
  AGENT_TOOLS_DIST_ROOT=$PWD/tests/publisher/expected \
  tools/publish-skills.sh --quiet --agents claude,grok,factory,codex,opencode
then review the diff before committing.
"""

import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PUBLISHER = REPO_ROOT / "tools" / "publish-skills.sh"
FIXTURE_SRC = Path(__file__).resolve().parent / "fixtures" / "src"
EXPECTED_ROOT = Path(__file__).resolve().parent / "expected"

AGENTS = ["claude", "grok", "factory", "codex", "opencode"]


def _tree(root: Path) -> dict[str, bytes]:
    """Map of relative posix path -> file bytes for every file under root."""
    return {
        p.relative_to(root).as_posix(): p.read_bytes()
        for p in sorted(root.rglob("*"))
        if p.is_file()
    }


class PublishGoldenTest(unittest.TestCase):
    maxDiff = None

    @classmethod
    def setUpClass(cls):
        cls._tmp = tempfile.TemporaryDirectory()
        cls.addClassCleanup(cls._tmp.cleanup)
        cls.dist_root = Path(cls._tmp.name) / "dist"
        env = os.environ.copy()
        env["AGENT_TOOLS_SRC_ROOT"] = str(FIXTURE_SRC)
        env["AGENT_TOOLS_DIST_ROOT"] = str(cls.dist_root)
        result = subprocess.run(
            [str(PUBLISHER), "--quiet", "--agents", ",".join(AGENTS)],
            env=env,
            capture_output=True,
            text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(
                f"publisher failed ({result.returncode}):\n"
                f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}"
            )

    def test_golden_tree_covers_exactly_the_tested_agents(self):
        # Guards against DEFAULT_AGENTS and this suite's AGENTS list
        # drifting apart: orphan golden dirs would never be compared.
        self.assertEqual(
            sorted(d.name for d in EXPECTED_ROOT.iterdir() if d.is_dir()),
            sorted(AGENTS),
        )

    def test_output_matches_goldens(self):
        for agent in AGENTS:
            with self.subTest(agent=agent):
                expected = _tree(EXPECTED_ROOT / agent)
                actual = _tree(self.dist_root / agent)
                self.assertEqual(
                    sorted(expected), sorted(actual),
                    f"file set for {agent} diverged from golden",
                )
                for rel in expected:
                    self.assertEqual(
                        expected[rel], actual[rel],
                        f"content diverged from golden: {agent}/{rel}",
                    )

    def test_pdf_build_is_skipped(self):
        for agent in AGENTS:
            self.assertFalse(
                (self.dist_root / agent / "skills" / "pdf-build").exists(),
                f"pdf-build/ must not be published for {agent}",
            )

    def test_dry_run_writes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            dist = Path(tmp) / "dist"
            env = os.environ.copy()
            env["AGENT_TOOLS_SRC_ROOT"] = str(FIXTURE_SRC)
            env["AGENT_TOOLS_DIST_ROOT"] = str(dist)
            result = subprocess.run(
                [str(PUBLISHER), "--dry-run", "--agents", "claude,opencode"],
                env=env,
                capture_output=True,
                text=True,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertFalse(dist.exists(), "--dry-run must not write files")
            self.assertIn("[dry]", result.stdout)


if __name__ == "__main__":
    unittest.main()
