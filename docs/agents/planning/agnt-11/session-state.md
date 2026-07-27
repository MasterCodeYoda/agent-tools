---
project: kevn-docker-primary-deploy
requirements_source: pm
work_item: AGNT-11
pm_tool: linear
session_count: 2
status: done
track: feature
decomposition: deliverable-partition
execution_home: agent-tools
branch: main
pending_gate: none
last_transition: "needs_compound → done (COMPOUND_DONE + MERGED)"
run_id: r-20260726-1
linear: https://linear.app/overlund-media/issue/AGNT-11
reentry_counts:
  refine_from_execute_or_review: 0
  plan_from_execute_or_review: 0
thrash_bound_hits: 0
source_channel: cli
review: findings-fixed | 2026-07-26 | method=work-review | P1=0 P2=2 P3=3 | disposition=P2 fixed in 773c02c; P3 deferred
compound: captured | 2026-07-26 | entries/profile-skill-bindings-track-published-names.md
---

## Progress

### Shipped

- Monorepo Kevin packaging under `hermes/` + `docs/agents/`
- Multi-arch GHCR `kevin-hermes` (`:main` + `:sha-…`)
- SF SoT retired; remote gone
- Review remediations: entrypoint fail-closed; work/* skill bindings; Isolated runbook language
- Linear AGNT-11 Done; compound memory entry for profile binding drift

### Residual (operator, non-blocking)

- `~/Source/OMG/software-factory-kevin-e5` leftover worktree — prune locally
- Workstation CLI + skills dist = follow-on (AGNT-12 / AGNT-13)

## Current Focus

Unit complete. NEXT for capability dogfood is Workstation Kevin (not invent from residual alone).
