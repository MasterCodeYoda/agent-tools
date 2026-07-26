---
title: Hermes H2 process pack PASS
type: lesson
tags: [hermes, process-pack, export, packaging, h2]
date: 2026-07-22
source: hermes-h2-process-pack (r-20260722-2)
---

# Hermes H2 process pack PASS

## Pattern

Do **not** hand-maintain SKILL.md under Hermes. Export from agent-tools:

```bash
# software-factory
scripts/export-process-pack.sh --full   # or --thin
```

Wraps `agent-tools/tools/publish-skills.sh --agents factory` → `packs/hermes-process-pack/skills`.

Wire: `skills.external_dirs: [<pack>/skills]` on a `--no-skills` factory profile.

## Mapping

`workflow:continue` (frontmatter) → directory `workflow-continue/` → Hermes lists `workflow:continue`.

## Gotchas

- Generated packs are gitignored; re-export after agent-tools evolve.
- Full pack ~36 top-level skills; use `--thin` for H1-shaped subset.
- Second profile dry-run: `factory-h2` proved install without SKILL edits.
