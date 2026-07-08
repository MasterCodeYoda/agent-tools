---
name: cross-agent-delegation-self-contained-baseline
description: Skills that prefer-delegate to a companion skill must carry a self-contained baseline; publishing gates by agent, not by skill availability
type: pattern
applicability: project
related:
  - src/skills/references/MARKUP.md
  - tools/publish-skills.sh
  - entries/publisher-strips-html-comments.md
promoted_at: "2026-07-08T22:29:35Z"
source_harness: claude
---

`tools/publish-skills.sh` is a static publish-time filter. Its only cross-agent lever is `agent:include` / `agent:exclude` markup. It gates content **by agent identity** (claude/grok/factory/codex) and strips comments. There is **no runtime skill-availability detection**.

When a corpus skill wants to prefer-delegate to a companion skill (e.g. `/workflow:brainstorm` preferring an external brainstorming skill), handle two independent axes:

1. **Agent axis** — gate the delegation mention behind `agent:include` for agents that can load the companion; Factory/Codex cannot be assumed to have Claude plugins.
2. **Plugin-presence axis** — even on Claude/Grok the companion may not be installed; phrase as conditional-on-availability ("if present, prefer…").

**Why:** A delegation-only skill silently breaks on agents without that companion.

**How to apply:** Author the real logic **unmarked** as the baseline so it runs on every agent; add delegation only as an agent-gated, availability-conditional *enrichment*, never as the engine. Overlap with the companion skill is expected and fine.
