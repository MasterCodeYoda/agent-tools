---
title: Hermes H1 factory profile PASS
type: lesson
tags: [hermes, factory-profile, process-pack, h1, packaging]
date: 2026-07-22
source: hermes-h1-factory-profile (r-20260722-1)
---

# Hermes H1 factory profile PASS

## What worked

- Dedicated profile `hermes profile create factory --no-skills` isolates from 78 default bundled skills.
- Process pack via `skills.external_dirs` (YAML **list**, not string) pointing at agentskills tree.
- Factory policy: memory off, `skills.write_approval: true`, `approvals.mode: manual`, plus `approvals.deny` globs for hard floor.
- Real product dogfood (Spectral): project disk is SoT; status/continue skills read roadmap only.
- Cleanup: `hermes uninstall --full`.

## Gotchas

- `hermes config set skills.external_dirs '["path"]'` stores a **string** — rewrite with real YAML list.
- Factory one-shots can run with **no `.env` API key** if Claude Code credentials land in profile `auth.json` (`source: claude_code`). Fine for personal dogfood; weak teammate story (H2).
- Shell installer may pull system deps (e.g. Homebrew ffmpeg).
- `platform_toolsets.cli` as list works when written as YAML list; config-set string form is unreliable.

## H1.9 outcome

All critical rows pass. Residuals: auth packaging, interactive approve UX, full process export (H2), product-surface project-bind gap.
