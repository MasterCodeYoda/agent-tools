"""Unit tests for the deterministic `ingest` bookend (stdlib unittest)."""

import shutil
import tempfile
import unittest
from pathlib import Path

from tests.swarm.harness.ingest import (
    extract_files_changed,
    ingest,
    parse_frontmatter,
    write_observations,
)


def _log(item, role, status, *, decision=True, files=None, push=False, return_block=True):
    fc = ""
    if files is not None:
        fc = "  files_changed: [" + ", ".join(files) + "]\n"
    dec = "## Decision log\n- [10:00] did a thing\n" if decision else ""
    push_line = "remember: never git push from here\n" if push else ""
    ret = ""
    if return_block:
        ret = (
            "## Return\n```yaml\n"
            f"status: {status}\nitem: {item}\nrole: {role}\nartifacts:\n{fc}```\n"
        )
    return (
        f"---\nrun_id: r1\nitem: {item}\nrole: {role}\nstatus: {status}\n---\n"
        f"## Dispatch context\n{push_line}prompt\n{dec}{ret}"
    )


class FrontmatterTests(unittest.TestCase):
    def test_parses_flat_pairs(self):
        fm = parse_frontmatter("---\nrole: planner\nstatus: DONE\nitem: 'x'\n---\nbody")
        self.assertEqual(fm, {"role": "planner", "status": "DONE", "item": "x"})

    def test_no_frontmatter(self):
        self.assertEqual(parse_frontmatter("no fm here"), {})


class FilesChangedTests(unittest.TestCase):
    def test_inline(self):
        self.assertEqual(extract_files_changed("files_changed: [a.py, b.py]"), ["a.py", "b.py"])

    def test_block(self):
        block = "artifacts:\n  files_changed:\n    - a.py\n    - b.py\n  test_status: pass\n"
        self.assertEqual(extract_files_changed(block), ["a.py", "b.py"])

    def test_absent(self):
        self.assertEqual(extract_files_changed("status: DONE\n"), [])


class IngestTests(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        self.sess = self.tmp / ".agent-tools/swarm/sessions/r1"

    def _write(self, item, name, content):
        d = self.sess / item
        d.mkdir(parents=True, exist_ok=True)
        (d / name).write_text(content)

    def test_counts_and_tallies(self):
        self._write("item-1", "implementer-1.md", _log("item-1", "implementer", "DONE", files=["src/app.py"]))
        self._write("item-1", "reviewer-1.md", _log("item-1", "reviewer", "APPROVED"))
        self._write("item-2", "planner-1.md", _log("item-2", "planner", "DONE"))
        obs = ingest(self.tmp)
        self.assertEqual(obs["run_id"], "r1")
        self.assertEqual(obs["dispatch_count"], 3)
        self.assertEqual(obs["status_tally"], {"DONE": 2, "APPROVED": 1})
        self.assertEqual(obs["by_role"]["implementer"]["dispatches"], 1)
        self.assertEqual(obs["items"]["item-1"]["roles_seen"], ["implementer", "reviewer"])
        self.assertEqual(obs["items"]["item-1"]["last_status"], "APPROVED")

    def test_malformed_and_missing_frontmatter(self):
        self._write("item-1", "planner-1.md", "garbage, no frontmatter\n")
        self._write("item-1", "implementer-1.md", _log("item-1", "implementer", "DONE", return_block=False))
        obs = ingest(self.tmp)
        reasons = {m["reason"] for m in obs["malformed_returns"]}
        self.assertIn("missing/!malformed frontmatter", reasons)
        self.assertIn("no parseable return block", reasons)
        # the no-frontmatter file is not counted as a dispatch
        self.assertEqual(obs["dispatch_count"], 1)

    def test_missing_decision_log_flagged(self):
        self._write("item-1", "reviewer-1.md", _log("item-1", "reviewer", "APPROVED", decision=False))
        obs = ingest(self.tmp)
        self.assertEqual(len(obs["missing_decision_logs"]), 1)

    def test_safety_signals(self):
        self._write("item-1", "reviewer-1.md",
                    _log("item-1", "reviewer", "FIX_REQUESTED", push=True,
                         files=["../other/secret.py", "/etc/passwd", "src/ok.py"]))
        obs = ingest(self.tmp)
        self.assertEqual(len(obs["safety"]["push_mentions"]), 1)
        oos = {w["path"] for w in obs["safety"]["out_of_scope_writes"]}
        self.assertEqual(oos, {"../other/secret.py", "/etc/passwd"})

    def test_no_sessions_tolerated(self):
        obs = ingest(self.tmp)  # nothing written
        self.assertEqual(obs["dispatch_count"], 0)
        self.assertTrue(any("no sessions" in w for w in obs["warnings"]))

    def test_write_observations(self):
        self._write("item-1", "planner-1.md", _log("item-1", "planner", "DONE"))
        obs = ingest(self.tmp)
        out = write_observations(self.tmp, obs)
        self.assertTrue(out.is_file())
        self.assertIn('"dispatch_count": 1', out.read_text())


if __name__ == "__main__":
    unittest.main()
