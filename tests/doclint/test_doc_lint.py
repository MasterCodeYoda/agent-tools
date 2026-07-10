"""Unit tests for tools/doc_lint.py.

Each test builds a minimal fake repo in a temp dir and runs the linter's
main() against it, asserting on findings and exit codes.

Stdlib unittest (no external deps) so it runs out-of-the-box via
`python -m unittest`; also discovered by pytest if installed.
"""

import contextlib
import io
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "tools"))

import doc_lint  # noqa: E402


class DocLintCase(unittest.TestCase):
    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.addCleanup(self._tmp.cleanup)
        # Minimal skill corpus: family `alpha` with a sub-skill and a reference.
        self.write("src/alpha/SKILL.md", "---\nname: alpha\n---\nbody\n")
        self.write(
            "src/alpha/setup/SKILL.md", "---\nname: alpha:setup\n---\nbody\n"
        )
        self.write("src/alpha/references/guide.md", "guide\n")

    def write(self, rel, content):
        path = self.root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def run_lint(self, *extra_args):
        """Run main() against the fake repo; return (exit_code, output)."""
        argv = ["--root", str(self.root), "--allowlist",
                str(self.root / "allow.txt"), *extra_args]
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = doc_lint.main(argv)
        return code, buf.getvalue()

    def assert_finding(self, output, fragment):
        self.assertIn(fragment, output)

    def assert_clean(self, code, output):
        self.assertEqual(code, 0, output)
        self.assertIn("0 finding(s)", output)

    # ── links ──────────────────────────────────────────────────────────

    def test_broken_relative_link_reported(self):
        self.write("src/alpha/doc.md", "[x](missing.md)\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "[link] broken link target: missing.md")

    def test_valid_relative_link_ok(self):
        self.write("src/alpha/doc.md", "[x](references/guide.md)\n")
        self.assert_clean(*self.run_lint())

    def test_link_inside_code_fence_skipped(self):
        self.write("src/alpha/doc.md", "```\n[x](missing.md)\n```\n")
        self.assert_clean(*self.run_lint())

    def test_template_placeholder_link_skipped(self):
        self.write("src/alpha/doc.md", "[x](./planning/<project>/plan.md)\n")
        self.assert_clean(*self.run_lint())

    def test_external_and_anchor_links_skipped(self):
        self.write(
            "src/alpha/doc.md",
            "[a](https://example.com/x.md) [b](#section) [c](mailto:x@y.z)\n",
        )
        self.assert_clean(*self.run_lint())

    # ── @refs ──────────────────────────────────────────────────────────

    def test_unknown_hyphenated_family_reported(self):
        self.write("src/alpha/doc.md", "see @missing-skill for details\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "unknown skill family: @missing-skill")

    def test_hyphen_variant_of_declared_subskill_ok(self):
        self.write("src/alpha/doc.md", "see @alpha-setup for details\n")
        self.assert_clean(*self.run_lint())

    def test_unknown_single_word_at_token_skipped(self):
        self.write("src/alpha/doc.md", "@pytest and @property decorators\n")
        self.assert_clean(*self.run_lint())

    def test_email_not_treated_as_atref(self):
        self.write("src/alpha/doc.md", "mail me at someone@missing-skill.com\n")
        self.assert_clean(*self.run_lint())

    def test_known_family_missing_target_reported(self):
        self.write("src/alpha/doc.md", "see @alpha (`references/gone.md`)\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "@alpha target not found: references/gone.md")

    def test_known_family_valid_target_ok(self):
        self.write(
            "src/alpha/doc.md",
            "see @alpha (references/guide.md) and @alpha (setup)\n",
        )
        self.assert_clean(*self.run_lint())

    def test_target_fragment_stripped(self):
        self.write("src/alpha/doc.md", "see @alpha (references/guide.md#part)\n")
        self.assert_clean(*self.run_lint())

    def test_descriptive_parenthetical_not_resolved(self):
        self.write("src/alpha/doc.md", "see @alpha (quality checkpoints)\n")
        self.assert_clean(*self.run_lint())

    def test_unknown_subskill_reported(self):
        self.write("src/alpha/doc.md", "run @alpha:gone now\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "unknown sub-skill: @alpha:gone")

    def test_atref_inside_fence_skipped(self):
        self.write("src/alpha/doc.md", "```\n@missing-skill\n```\n")
        self.assert_clean(*self.run_lint())

    # ── commands ───────────────────────────────────────────────────────

    def test_unknown_colon_command_reported_even_in_fence(self):
        self.write("src/alpha/doc.md", "```\n/alpha:gone arg\n```\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "unknown command: /alpha:gone")

    def test_short_family_colon_commands_are_checked(self):
        # Regression: families shorter than 3 chars (like the real `qa`)
        # must still be matched in colon form.
        self.write("src/io/SKILL.md", "---\nname: io\n---\nbody\n")
        self.write("src/io/run/SKILL.md", "---\nname: io:run\n---\nbody\n")
        self.write("src/io/doc.md", "run /io:run then /io:gone\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "unknown command: /io:gone")
        self.assertNotIn("/io:run", out)

    def test_declared_colon_and_hyphen_commands_ok(self):
        self.write("src/alpha/doc.md", "/alpha:setup or /alpha-setup or /alpha\n")
        self.assert_clean(*self.run_lint())

    def test_unknown_bare_command_reported_in_prose(self):
        self.write("src/alpha/doc.md", "run /vanished to proceed\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "stale reference: /vanished")

    def test_bare_command_inside_fence_skipped(self):
        self.write("src/alpha/doc.md", "```\ncurl localhost/register\n/register\n```\n")
        self.assert_clean(*self.run_lint())

    def test_filesystem_and_template_paths_not_commands(self):
        self.write(
            "src/alpha/doc.md",
            "see dist/claude/skills/ and `planning/<project>/session-state.md`\n",
        )
        self.assert_clean(*self.run_lint())

    # ── intra-skill paths ──────────────────────────────────────────────

    def test_missing_intra_skill_path_reported(self):
        self.write("src/alpha/doc.md", "see `references/gone.md` for more\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "intra-skill path not found: references/gone.md")

    def test_intra_skill_path_reported_inside_fence(self):
        self.write("src/alpha/doc.md", "```\n- per `implementation/x.md`\n```\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "intra-skill path not found: implementation/x.md")

    def test_intra_skill_path_resolves_via_family_root(self):
        self.write("src/alpha/sub/doc.md", "see `references/guide.md`\n")
        self.assert_clean(*self.run_lint())

    def test_intra_skill_path_resolves_via_mentioned_family(self):
        self.write("src/beta/SKILL.md", "---\nname: beta\n---\nbody\n")
        self.write(
            "src/beta/doc.md",
            "uses @alpha (`references/guide.md`, `references/guide.md`)\n",
        )
        self.assert_clean(*self.run_lint())

    # ── allowlist ──────────────────────────────────────────────────────

    def test_allowlist_command_entry(self):
        self.write("src/alpha/doc.md", "run /external-tool now\n")
        self.write("allow.txt", "command external-tool\n")
        self.assert_clean(*self.run_lint())

    def test_allowlist_ref_entry(self):
        self.write("src/alpha/doc.md", "see @legacy-thing and [x](legacy-thing.md)\n")
        self.write("allow.txt", "ref legacy-thing\n")
        self.assert_clean(*self.run_lint())

    def test_allowlist_family_entry(self):
        self.write("src/alpha/doc.md", "see @other-corpus for details\n")
        self.write("allow.txt", "family other-corpus\n")
        self.assert_clean(*self.run_lint())

    def test_allowlist_file_scoped_entry(self):
        self.write("src/alpha/history.md", "old `references/gone.md` note\n")
        self.write("allow.txt", "file src/alpha/history.md references/\n")
        self.assert_clean(*self.run_lint())

    def test_file_scoped_entry_does_not_leak_to_other_files(self):
        self.write("src/alpha/doc.md", "see `references/gone.md`\n")
        self.write("allow.txt", "file src/alpha/history.md references/\n")
        code, _ = self.run_lint()
        self.assertEqual(code, 1)

    def test_malformed_allowlist_is_config_error(self):
        self.write("src/alpha/doc.md", "clean\n")
        self.write("allow.txt", "bogus entry kind\n")
        code, _ = self.run_lint()
        self.assertEqual(code, 2)

    # ── modes and scope ────────────────────────────────────────────────

    def test_report_only_exits_zero_with_findings(self):
        self.write("src/alpha/doc.md", "[x](missing.md)\n")
        code, out = self.run_lint("--report-only")
        self.assertEqual(code, 0)
        self.assert_finding(out, "broken link target")

    def test_fixture_dirs_excluded(self):
        self.write(
            "tests/publisher/fixtures/src/x/doc.md", "[x](missing.md)\n"
        )
        self.write(
            "tests/publisher/expected/claude/skills/x/doc.md", "[x](gone.md)\n"
        )
        self.write(
            "tests/skill-eval/scenarios/foo/code/README.md", "[x](gone.md)\n"
        )
        self.write(
            "tests/swarm/history/2026-01-01-run/orchestrator.md",
            "see @ec208a4 and [x](gone.md)\n",
        )
        self.assert_clean(*self.run_lint())

    def test_non_excluded_tests_files_are_linted(self):
        # Guards against the exclusion list silently swallowing all of
        # tests/ — a violation outside the fixture globs must be reported.
        self.write("tests/notes.md", "[x](missing-design.md)\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "tests/notes.md:1")

    def test_readme_is_linted(self):
        self.write("README.md", "[x](missing-doc.md)\n")
        code, out = self.run_lint()
        self.assertEqual(code, 1)
        self.assert_finding(out, "README.md:1")


if __name__ == "__main__":
    unittest.main()
