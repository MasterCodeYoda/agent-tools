# Built-in work tracks

**Load when:** unit mode classifies a claimed unit, or `/workflow:setup` authors track
conventions. Built-in tracks are always available; `planning/conventions.md` may add more or
tune classification — it does not need to restate the feature track unless documenting
project-local overrides.

## Tracks

| Track | Purpose | Primary path |
|-------|---------|--------------|
| **feature** | Default full production line | brainstorm? → refine → plan → execute → review → integrate → compound |
| **micro** | Clear small work; issue/paste is the plan | confirm → execute → review (`quick`) → integrate → compound disposition |
| **research** | Orientation / evaluate / decide — not ship-by-default | frame → evidence → conclusion (user-gated) → compound disposition |

Project conventions may alias **`direct` → micro**. Extra tracks still override the feature
table only for units they classify (setup doctrine).

## Classification (first match; user override always wins)

User flags: `micro` / `direct` / `small` / `research` / `full` / `plan this` / `heavy`.

### → micro when any hold

1. User flag: `micro` | `direct` | `small` | “just fix it”
2. Labels/types: `bug`, `chore`, `docs` (or project equivalents)
3. Issue or paste **is the plan**: clear repro **or** AC checklist **or** single concrete change
4. No new public contract (API/schema/auth/permissions); not multi-unit; not architecture spike

### → research when any hold

1. User flag: `research` | `spike` | `evaluate`
2. Labels: `research`, `spike` (or project equivalents)
3. Success is a **decision or scored experiment**, not merged product code by default
4. Framing language: “should we…”, “evaluate X”, “runtime bet”, orientation without ship target

### → feature (standard) otherwise

Including new public contracts, multi-module design, ambiguous success, multi-session scope,
or user `full` / `plan this` / `heavy`.

### Multi-unit program

No track → hard-stop + offer `/workflow:roadmap`. Do not stuff a program into micro or research.

## Micro process (continue unit machine)

| State | Meaning |
|-------|---------|
| `ready_execute` | Confirmed scope (issue confirmation = plan approval) |
| `needs_review` | Code landed; need valid review evidence (`depth=quick` default) |
| `needs_integrate` | Reviewed clean |
| `needs_compound` | Merged; capture or `compound: none — <reason>` |
| `done` | Compound disposition recorded |

**Skip** brainstorm, refine shell, and implementation-plan markdown unless escalate.

**Mandatory:** branch ≠ main; tests green; real review + evidence schema; escalate when scope
grows (new contract, multi-module, unclear ACs, thrash). On escalate → reclassify **feature**
and enter `needs_plan` or `needs_refine` with evidence.

**Invoke:** `@workflow:execute` direct-issue path (`execution/references/direct-issue-execution.md`)
or the same loop with issue-as-plan; do not force `requirements.md` / `implementation-plan.md`.

**After plan approve (feature track only):** same-session execute (no emit-and-stop default).

## Research process

| State | Meaning |
|-------|---------|
| `research_framed` | One-sentence question + success = decision/experiment; time box |
| `research_evidence` | Notes under `docs/research/` or planning unit notes |
| `research_conclusion` | User-gated adopt / reject / hybrid / defer |
| `needs_compound` | Conclusion recorded; capture reusable criteria or reasoned none |
| `done` | Compound disposition + user would not reopen without new external evidence |

### Not-done signals (refuse `done` if present)

- Status still exploring / no conclusion written
- Open questions that block the decision
- Listed unknown still required for adopt/reject
- User has not acked a drafted conclusion when one was presented

**Done is a judgment call.** Agents only block on greppable not-done signals; they do not invent
a positive checklist theater.

**Code spikes:** if commits land, review applies to the spike (`quick`/`standard`); the
**conclusion doc** remains the primary deliverable. Optional promote to feature units after adopt.

Process detail may live in `planning/research-loop.md` when setup authors it; this table is the
built-in minimum when the file is absent.

## Review depth by track

| Track | Default depth |
|-------|----------------|
| micro | `quick` — single-pass structured review; still emits method + P1–P3 counts |
| feature | `standard` |
| research (code spike) | `quick` or `standard` by size |
| user `deep` / heavy / security-sensitive paths | `deep` |

Depth changes **dose**, not the review gate. Green tests ≠ reviewed. Infer depth; state it;
user may override. Do not skip review for code-bearing work.

`/workflow:review` **does not ask** depth by default — resolve from track → flags → diff size
(see review skill §4). Continue passes `track` via session-state when invoking review.

## Personal factory profile (conventions pack)

When setup interviews “personal factory” (or the user asks for that profile), write a sparse
`conventions.md` that includes micro + research tracks, `visual: never`, PM mode if used,
**autonomous local merge when ratchet green**, push/PR user-initiated. See setup template
`setup/templates/personal-factory-conventions.md`.
