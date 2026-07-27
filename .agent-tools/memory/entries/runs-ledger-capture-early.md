---
name: runs-ledger-capture-early
description: Stamp runs identity envelope on claim; capture early analyze late; rework ≠ review_fix
type: pattern
applicability: project
related:
  - src/work/references/runs-ledger.md
  - src/work/references/process-payload.md
  - run_id:r-20260727-1
incident_date: null
job_phases: [continue, compound, maintain]
promoted_at: null
promoted_to: null
source_harness: grok
---

# Runs ledger: capture early, analyze late

## Why

Harness, model, skills_rev, and workspace_kind are **non-reconstructible** after the fact.
Deferring instrumentation until “we need metrics” loses Kevin vs Grok and product-repo vs
skill-source history. Fancy yield/evolve *readers* can wait; the **envelope** cannot.

## How to apply

1. On claim: mint `run_id` + stamp identity fields on session-state (unknown allowed).
2. Every phase-return: wall-clock `ts`, full identity echo, optional `dose`.
3. Close: `rework` only for execute/review→refine/plan (or thrash); use `review_fix_cycles`
   for in-place review fixes; deferred P counts; `ttm_hours` when first/last ts are real.
4. Product repos: write local `.agent-tools/runs/` — do not skip until “export to skill-source.”
5. Kevin: `harness=kevin-hermes`, `profile=kevin`, skills_rev from Kevin skills root; prefer
   `KEVIN_RUN_*` env from `kevin start`.
