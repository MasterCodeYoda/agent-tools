---
name: kevin-foundation-cleanup
description: Foundation cleanup done 2026-07-24 — docs taxonomy, hermes scaffold, kevin-v1 register; next Linear AGNT
type: process
applicability: project
related:
  - docs/kevin-v1.md
  - docs/handoff.md
  - hermes/README.md
promoted_at: null
promoted_to: null
source_harness: factory
---

# Kevin foundation cleanup

## Why

Dogfood research lived flat under `docs/` with stale README/handoff; residual DoD lived in gitignored planning units. Cold sessions could not execute Kevin build reliably.

## How to apply

1. Start at `docs/handoff.md` → ADR-001 → `docs/kevin-v1.md`.  
2. Research is **archive** under `docs/research/`.  
3. Config-as-code home is `hermes/` (scaffold).  
4. Do **not** invent NEXT until Linear AGNT + roadmap rechart.  
5. Process pack: re-export only; packs/hermes-process-pack* gitignored.  
