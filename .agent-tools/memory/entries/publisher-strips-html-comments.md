---
name: publisher-strips-html-comments
description: agent-tools publisher strips ALL complete HTML comments from skills — literal markers in output instructions get silently erased
type: gotcha
applicability: project
related:
  - src/skills/references/MARKUP.md
  - tools/publish-skills.sh
promoted_at: "2026-07-08T22:29:35Z"
source_harness: claude
---

`tools/publish-skills.sh` (the awk `filter_for_agent`) strips **every** line matching a complete HTML comment — not just the `agent:include` / `agent:exclude` markup tags. Mandated by `src/skills/references/MARKUP.md` ("Strip all HTML comments from the final output").

**Why:** Skills that instruct agents to write marker-bounded blocks into `AGENTS.md` (e.g. charter-link, memory-link) must not embed a complete comment on one source line — the publisher erases those lines, breaking both the write instruction and idempotent re-detection.

**How to apply:** When a skill must emit a *literal* HTML comment in its output:

1. Describe the marker by its **inner content** (e.g. content is exactly `agent-tools:charter-link begin`).
2. Use placeholder tokens like `[[BEGIN-MARKER]]` in templates.
3. To mention delimiters in prose, split them so they are non-contiguous.

Verify after publishing with a search for the inner text under `dist/<agent>/skills/`.

**Verification gotchas:** `--agents` is comma-separated (`--agents claude,grok,factory`). `--dry-run` flattened-leaf output reads the *existing* `dist/` tree — brand-new skills need a real `setup.sh` + direct `dist/` inspection.
