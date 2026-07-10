#!/usr/bin/env python3
"""Doc-integrity linter for the agent-tools skill corpus.

Validates three reference classes in src/**/*.md, tests/**/*.md, and
README.md against the actual repo tree:

  link     relative markdown links (outside fenced code blocks) must
           resolve to an existing file or directory
  atref    @skill references: the family must be a src/ skill (or an
           allowlisted external); a path-like parenthetical target must
           resolve under the family's src/ directory
  command  slash commands (/family:sub or bare /name) must match a
           declared `name:` in some src/**/SKILL.md (colon or hyphen
           form) or an allowlisted external command

Findings print as `path:line: [class] message`. Exit codes: 0 clean,
1 findings (0 with --report-only), 2 usage/config error.

False positives are suppressed via tools/doc-lint-allowlist.txt — see
that file's header for the format.

Stdlib only; no third-party dependencies.
"""

import argparse
import fnmatch
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_ALLOWLIST = Path(__file__).resolve().parent / "doc-lint-allowlist.txt"

# Directories under src/ that are not skills (mirrors the publisher's SKIP_DIRS)
SKIP_DIRS = {"pdf-build"}

# Fixture and captured-run data: content is test *data* by design (including
# intentional violations), not authored documentation. Never linted.
FIXTURE_EXCLUDES = (
    "tests/publisher/fixtures/*",
    "tests/publisher/expected/*",
    "tests/skill-eval/scenarios/*/code/*",
    "tests/swarm/history/2*",
)

FENCE_RE = re.compile(r"^\s*(```|~~~)")
LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
# @family or @family:sub, optionally followed by a parenthetical target.
# Must be delimited on the left so emails/handles-in-prose don't match.
ATREF_RE = re.compile(
    r"(?:^|(?<=[\s`(\[>]))@([a-z][a-z0-9_-]*(?::[a-z][a-z0-9-]*)?)"
    r"(?:\s+\((`?)([^)`]+)\2\))?"
)
# /family:sub or bare /name, delimited so filesystem paths (including
# template paths like `<project>/file.md`) don't match. The colon form
# allows short families (/qa:setup); the bare form keeps a 3-char floor
# to avoid short prose tokens.
COMMAND_RE = re.compile(
    r"(?:^|(?<=[\s`(\[\"']))"
    r"/((?:[a-z][a-z0-9-]*:[a-z][a-z0-9-]*)|[a-z][a-z0-9-]{2,})"
    r"(?=$|[\s`)\]\"'.,;:](?!\S*/)|[.,;:]?$)"
)
NAME_FRONTMATTER_RE = re.compile(r"^name:\s*(\S+)\s*$", re.MULTILINE)
# Inline-code intra-skill paths (`references/x.md`). The leading-segment
# vocabulary is curated: these directory names only ever mean "inside this
# skill" — unlike e.g. `planning/`, which usually refers to a target project.
INTRA_SKILL_PATH_RE = re.compile(
    r"`\.?/?((?:references|examples|implementation|execution|templates|domains)"
    r"/[A-Za-z0-9._/-]+\.md)(?:#[A-Za-z0-9_-]+)?`"
)

# Characters that mark a link target as a template placeholder, not a path
TEMPLATE_CHARS = set("<>[]{}$*|")


class Allowlist:
    """Parsed doc-lint-allowlist.txt.

    Line forms (see the allowlist file header):
      family <name>
      command <name>
      ref <substring>
      file <glob> <substring>
    """

    def __init__(self):
        self.families = set()
        self.commands = set()
        self.refs = []
        self.file_refs = []  # (glob, substring)

    @classmethod
    def load(cls, path):
        allow = cls()
        if not path.exists():
            return allow
        for raw in path.read_text(encoding="utf-8").splitlines():
            line = raw.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split(None, 2)
            kind = parts[0]
            if kind == "family" and len(parts) == 2:
                allow.families.add(parts[1])
            elif kind == "command" and len(parts) == 2:
                allow.commands.add(parts[1])
            elif kind == "ref" and len(parts) >= 2:
                allow.refs.append(line.split(None, 1)[1])
            elif kind == "file" and len(parts) == 3:
                allow.file_refs.append((parts[1], parts[2]))
            else:
                raise ValueError(f"malformed allowlist line: {raw!r}")
        return allow

    def permits(self, rel_file, target):
        if any(sub in target for sub in self.refs):
            return True
        return any(
            fnmatch.fnmatch(rel_file, glob) and sub in target
            for glob, sub in self.file_refs
        )


def collect_declared_names(src_root):
    """All `name:` values from src/**/SKILL.md, plus hyphenated variants."""
    names = set()
    for skill_md in src_root.rglob("SKILL.md"):
        if any(part in SKIP_DIRS for part in skill_md.parts):
            continue
        match = NAME_FRONTMATTER_RE.search(skill_md.read_text(encoding="utf-8"))
        if match:
            name = match.group(1)
            names.add(name)
            names.add(name.replace(":", "-"))
    return names


def iter_content_lines(text):
    """Yield (lineno, line, in_fence) for every line of a markdown file."""
    in_fence = False
    for lineno, line in enumerate(text.splitlines(), start=1):
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        yield lineno, line, in_fence


def check_links(rel_file, lineno, line, file_dir, findings, allow):
    for match in LINK_RE.finditer(line):
        target = match.group(1)
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        if TEMPLATE_CHARS & set(target):
            continue
        path_part = target.split("#", 1)[0]
        if not path_part:
            continue
        if allow.permits(rel_file, target):
            continue
        base = REPO_ROOT if path_part.startswith("/") else file_dir
        resolved = (base / path_part.lstrip("/")).resolve()
        if not resolved.exists():
            findings.append(
                (rel_file, lineno, "link", f"broken link target: {target}")
            )


def resolve_atref_target(family_dir, target):
    """A path-like @ref target must resolve under the family's src dir."""
    target = target.split("#", 1)[0]
    candidates = [
        family_dir / target,
        family_dir / f"{target}.md",
        family_dir / target / "SKILL.md",
    ]
    return any(c.exists() for c in candidates)


def check_atrefs(rel_file, lineno, line, src_root, declared, findings, allow):
    for match in ATREF_RE.finditer(line):
        name, _, target = match.group(1), match.group(2), match.group(3)
        family = name.split(":", 1)[0]
        if family in allow.families:
            continue
        if allow.permits(rel_file, f"@{name}"):
            continue
        family_dir = src_root / family
        if not family_dir.is_dir():
            if name in declared:
                # Hyphen variants of declared sub-skills (@alpha-setup).
                continue
            # Single-word unknown @tokens are overwhelmingly decorators,
            # annotations, or social handles (@pytest, @property,
            # @renedotwang). Skill families in this corpus are hyphenated
            # or colon-namespaced, so only those forms are reported.
            if "-" in name or ":" in name:
                findings.append(
                    (rel_file, lineno, "atref",
                     f"unknown skill family: @{name}")
                )
            continue
        if ":" in name and name not in declared:
            findings.append(
                (rel_file, lineno, "atref", f"unknown sub-skill: @{name}")
            )
            continue
        if target:
            # Descriptive parentheticals ("PM integration") are not paths.
            path_like = " " not in target and ("/" in target or "." in target
                                               or (family_dir / target).exists())
            if path_like and not allow.permits(rel_file, target):
                if not resolve_atref_target(family_dir, target):
                    findings.append(
                        (rel_file, lineno, "atref",
                         f"@{family} target not found: {target}")
                    )


def check_commands(rel_file, lineno, line, declared, findings, allow,
                   in_fence):
    for match in COMMAND_RE.finditer(line):
        name = match.group(1)
        if name in declared or name in allow.commands:
            continue
        if allow.permits(rel_file, f"/{name}"):
            continue
        if ":" in name:
            findings.append(
                (rel_file, lineno, "command", f"unknown command: /{name}")
            )
        elif not in_fence:
            # Bare-form names inside code fences are dominated by URL/endpoint
            # paths (/tasks, /register); only prose occurrences are reported.
            findings.append(
                (rel_file, lineno, "command",
                 f"unknown command or stale reference: /{name}")
            )


def skill_family_dir(path, src_root):
    """The src/<family>/ directory containing path, if any."""
    try:
        rel = path.relative_to(src_root)
    except ValueError:
        return None
    return src_root / rel.parts[0] if rel.parts else None


def check_intra_skill_paths(rel_file, lineno, line, file_dir, family_dir,
                            src_root, findings, allow):
    # A path may belong to a family referenced on the same line
    # (`@test-strategy (`references/a.md`, `references/b.md`)`), so those
    # families' src dirs are additional resolution bases.
    bases = [file_dir] + ([family_dir] if family_dir else [])
    for atref in ATREF_RE.finditer(line):
        mentioned = src_root / atref.group(1).split(":", 1)[0]
        if mentioned.is_dir():
            bases.append(mentioned)
    for match in INTRA_SKILL_PATH_RE.finditer(line):
        target = match.group(1)
        if allow.permits(rel_file, target):
            continue
        if not any((base / target).exists() for base in bases):
            findings.append(
                (rel_file, lineno, "path",
                 f"intra-skill path not found: {target}")
            )


def lint_file(path, src_root, declared, findings, allow):
    rel_file = path.relative_to(REPO_ROOT).as_posix()
    text = path.read_text(encoding="utf-8")
    file_dir = path.parent
    family_dir = skill_family_dir(path, src_root)
    for lineno, line, in_fence in iter_content_lines(text):
        if not in_fence:
            check_links(rel_file, lineno, line, file_dir, findings, allow)
            # @refs inside fences are Python decorators and shell noise,
            # never skill references; skip them there.
            check_atrefs(rel_file, lineno, line, src_root, declared,
                         findings, allow)
        check_commands(rel_file, lineno, line, declared, findings, allow,
                       in_fence)
        check_intra_skill_paths(rel_file, lineno, line, file_dir, family_dir,
                                src_root, findings, allow)


def gather_files(repo_root):
    files = []
    for base in ("src", "tests"):
        root = repo_root / base
        if not root.is_dir():
            continue
        for p in sorted(root.rglob("*.md")):
            if any(part in SKIP_DIRS for part in p.parts):
                continue
            rel = p.relative_to(repo_root).as_posix()
            if any(fnmatch.fnmatch(rel, g) for g in FIXTURE_EXCLUDES):
                continue
            files.append(p)
    readme = repo_root / "README.md"
    if readme.exists():
        files.append(readme)
    return files


def main(argv=None):
    global REPO_ROOT
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--root", type=Path, default=REPO_ROOT,
                        help="repo root to lint (default: this repo)")
    parser.add_argument("--allowlist", type=Path, default=DEFAULT_ALLOWLIST,
                        help="allowlist file (default: tools/doc-lint-allowlist.txt)")
    parser.add_argument("--report-only", action="store_true",
                        help="print findings but always exit 0")
    args = parser.parse_args(argv)

    REPO_ROOT = args.root.resolve()
    src_root = REPO_ROOT / "src"
    if not src_root.is_dir():
        print(f"error: no src/ under {REPO_ROOT}", file=sys.stderr)
        return 2

    try:
        allow = Allowlist.load(args.allowlist)
    except ValueError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2

    declared = collect_declared_names(src_root)
    findings = []
    files = gather_files(REPO_ROOT)
    for path in files:
        lint_file(path, src_root, declared, findings, allow)

    for rel_file, lineno, kind, message in findings:
        print(f"{rel_file}:{lineno}: [{kind}] {message}")
    print(f"doc-lint: {len(findings)} finding(s) across {len(files)} file(s)")

    if findings and not args.report_only:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
