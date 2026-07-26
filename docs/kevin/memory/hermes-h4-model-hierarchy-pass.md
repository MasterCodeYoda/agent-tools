---
title: Hermes H4 model hierarchy PASS
type: lesson
tags: [hermes, models, hierarchy, h4]
date: 2026-07-22
source: hermes-h4-model-hierarchy (r-20260722-4)
---

# Hermes H4 model hierarchy PASS

## Pattern

Map product hierarchy onto Hermes knobs — do not wait for a first-class phase→model tree:

| Role | Default |
|------|---------|
| Orchestrate | Opus (or strong Sonnet) via `/model` when needed |
| Execute | Profile default Sonnet |
| Auxiliary | Haiku compression |

Policy: `packs/factory-model-hierarchy.md`.

## Verified

`hermes -p factory --provider anthropic -m claude-{opus,sonnet,haiku}-…` one-shots all OK under Claude Code auth pool.
