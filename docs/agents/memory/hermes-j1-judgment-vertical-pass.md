---
title: Hermes J1 judgment vertical PASS
type: lesson
tags: [hermes, factory, judgment-automation, j1, spectral, controller]
date: 2026-07-22
source: hermes-j1-judgment-vertical (r-20260722-j1)
---

# J1 judgment vertical PASS

## What we proved

- **Lean (A):** controller + project disk + agent-tools pack; host is pluggable (this run: CLI operator-as-controller on Spectral worktree, not Hermes cron).
- Named micro unit only (`factory-j1-probe`); no invent NEXT.
- Safe-band execute → **valid review evidence** (method, date, verdict, P1–P3, disposition).
- **Agent-level overlay:** always-PR; never autonomous local-merge (overrides Spectral human local-merge default).
- **E-MERGE escalate** recorded on disk (`pending_gate`); human chose close without merge; resume from session-state.
- Isolation: primary checkout (SPEC-837 dirty) untouched; worktree `spectral-worktrees/factory-j1` only.

## Artifacts

- PR: https://github.com/overlund-media/spectral/pull/6 (CLOSED, not merged)
- Commit on branch: `52e36e7d` `docs/ops/factory-j1-judgment-probe.md`
- Brief: `.agent-tools/planning/hermes-j1-judgment-vertical/j1-brief.md`

## Implications

- Always-PR vs project local-merge is a **policy overlay**, not a second process dialect.
- Close-without-merge is a valid integrate disposition for disposable probes when open-PR + stop was the proof.
- Next risk for H5 is not packaging (H1–H4) but **automated** controller wakes (cron/Hermes) with the same disk predicates — J1 was operator-driven.

## Do not

- Treat J1 as “Hermes foundation adopted.”
- Merge factory probes into product main by default.
