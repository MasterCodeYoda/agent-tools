---
name: publisher-strips-html-comments
description: agent-tools publisher strips HTML comments outside fenced code — fence or backtick any literal comment markers a skill must emit
type: gotcha
applicability: project
related:
  - src/skills/references/MARKUP.md
  - tools/publish-skills.sh
  - tests/publisher/
promoted_at: "2026-07-08T22:29:35Z"
source_harness: claude
---

`tools/publish-skills.sh` (the awk `filter_for_agent`) strips **all** HTML comments from
published `.md` files — but only **outside fenced code blocks**. Exact semantics (specced in
`src/skills/references/MARKUP.md` §7, pinned by golden tests in `tests/publisher/`):

- **Fenced code (``` or ~~~) publishes verbatim** — comments and even `agent:include` tags
  inside a fence are content, never stripped or parsed (region filtering still applies).
- **Backticked comment literals in prose survive** (`` `<!-- ... -->` ``).
- Unfenced comments are stripped: whole-line and multi-line comments drop entirely; an inline
  comment is removed with the surrounding text preserved.
- `agent:include`/`agent:exclude` tags are directives **only at line start**; a mid-line or
  backticked mention is prose.

**Why:** Skills that instruct agents to write marker-bounded blocks into `AGENTS.md` (e.g.
charter-link, memory-link) historically lost those markers at publish. The old filter was
worse — it also deleted whole lines containing inline comments and let the corpus's own
documentation examples corrupt published output (MARKUP.md shipped at half length).

**How to apply:** When a skill must emit a *literal* HTML comment in its output, put the
template in a **fenced code block** (preferred) or backtick the marker inline. Unfenced bare
comment markers in prose will still be erased.

**Verify** after publishing by searching for the marker text under `dist/<agent>/skills/`.
`--agents` is comma-separated. Behavior changes to the filter must regenerate the golden
trees (`tests/publisher/test_publish.py` docstring has the recipe) and be reviewed by eye.
