# Runbook: Kevin coding-loop confidence (E5 / AGNT-6)

**Status:** Active gate  
**Profile:** `hermes -p kevin` only (direct tool loop)  
**Related:** [kevin-v1.md](../kevin-v1.md) · [ADR-001 §3](../decisions/001-hermes-provisional-factory-host.md) · [hermes-kevin.md](./hermes-kevin.md) · [product-surface.md](../product-surface.md)  
**Evidence:** [../evidence/kevin-coding-confidence/scorecard.md](../evidence/kevin-coding-confidence/scorecard.md)

---

## Intent

Prove that the Kevin Hermes host sits in an **equitable band** with the operator’s daily coding harness for real implement loops — not packaging theater, not shell-out architecture.

**This gate blocks declaring unattended *implement* trusted** ([AGNT-7](https://linear.app/overlund-media/issue/AGNT-7)). Packaging (E1–E4) may proceed without it.

---

## Preconditions

1. Bring-up hard bar green: `./scripts/kevin-bring-up-check.sh` (see [hermes-kevin.md](./hermes-kevin.md)).  
2. Provider auth works for the execute model class (`hermes -p kevin -z "ping"` style check).  
3. **Isolated git worktree** of a real product repo — never dirty primary as the tracer home.  
4. Named tasks only — do not invent product backlog units for the product repo under test.

---

## Baseline

| Field | Rule |
|-------|------|
| Daily harness | Operator’s usual implement host (Grok Build, Claude Code, etc.) |
| Model class | Same class as kevin execute default (Sonnet-class / equivalent) |
| Compare | Operator judgment bands, not CI flakiness |
| Not allowed as success | Hermes shelling out to a foreign coding **app** as the session host |

Fill the baseline row in the [scorecard](../evidence/kevin-coding-confidence/scorecard.md) before scoring tracers.

---

## Tracer shapes (need ≥2 of 3; prefer 3)

| ID | Shape | Requirements |
|----|-------|----------------|
| T1 | **Bug fix** | Localized defect or real gap; clear expected behavior |
| T2 | **Multi-file** | ≥2 files; real product change with reviewable DoD |
| T3 | **Recovery** | Wrong path or review finding → rework without thrash |

Each tracer:

1. Runs on **`hermes -p kevin`** from the product worktree cwd.  
2. May use process skills from managed `~/.hermes/skills`.  
3. Leaves git evidence (commits/branch) on the worktree branch.  
4. Records notes in the scorecard (task, model, turns/time estimate, rework, thrash, band).

---

## Scoring bands (1–5)

| Dimension | 1 | 3 | 5 |
|-----------|---|---|---|
| **Turns** | Far more than baseline | ~parity | Fewer / smoother |
| **Wall time** | Much slower | ~parity | Similar or faster |
| **Rework** | Large rewrites | Small patches | First-pass close |
| **Thrash** | Oscillates / wrong files | One wrong turn recovered | Clean path |

**PASS (all required):**

- ≥2 of 3 shapes completed (prefer all three)  
- For each completed tracer, **majority of dimensions within ±1** of baseline  
- Direct kevin loop only (no shell-out architecture)  
- Invent / isolation rules held  

**FAIL:** record dimensions missed + choose a fail path (below). Fail is a valid **gate conclusion**.

---

## Fail paths

| Path | When | Action |
|------|------|--------|
| **A — Tune** | Close but host knobs/skills/config wrong | Fix profile/pack/prompts; re-run tracers |
| **B — Host pivot** | Structural implement gap on Hermes | Pivot default host under lean A (e.g. pi/OpenCode); keep process SoT |
| **C — Shell-out last** | Only after A/B insufficient | Shell-out as temporary execution home **requires product-surface reopen** |

Do **not** skip to C because A is annoying.

---

## Operator procedure

```bash
# 0 — project check
cd /path/to/software-factory
./scripts/kevin-bring-up-check.sh

# 1 — isolated worktree of product under test
cd /path/to/product-repo
git worktree add ../product-kevin-e5 -b chore/kevin-coding-confidence main

# 2 — baseline row in scorecard (software-factory evidence path)

# 3 — run each tracer from worktree
cd ../product-kevin-e5
hermes -p kevin
# or non-interactive:
# hermes -p kevin -z "<task prompt>" --yolo   # only if approvals allow

# 4 — fill scorecard; decide PASS/FAIL

# 5 — cleanup
cd /path/to/product-repo
git worktree remove ../product-kevin-e5
```

---

## Out of scope

- Unattended wake / cron implement (AGNT-7)  
- Declaring PASS from doctor/skills alone  
- Synthetic fixture-only “success”  
- Dual process dialect  

---

## References

- J1 isolation pattern: `.agent-tools/planning/hermes-j1-judgment-vertical/j1-brief.md` (software-factory)  
- Model hierarchy: `packs/kevin-model-hierarchy.md`
