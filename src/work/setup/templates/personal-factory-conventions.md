# Project Work Conventions

> Personal factory profile — sparse overlay. Maintained by `/work:setup`.
> Any section omitted keeps the skill’s built-in default.

## Requirements source

pm (linear)
<!-- or: file -->

## Work tracks

### Default feature track

brainstorm → refine → plan → execute → review → finish → compound

### micro

- **When:** clear bug / small enhancement / docs / chore; issue or paste is the plan; no new
  public contract; user `micro`|`direct`|`small` — see @work `references/tracks.md`
- **Process:** confirm scope → execute (direct-issue) → review depth=quick → integrate →
  compound disposition. Issue confirmation = plan approval.
- **Overrides** the feature-track phase table for these units.
- **Escalate** to feature (`needs_plan` / `needs_refine`) when scope grows.

### research

- **When:** orientation, evaluate/spike, “should we…”, decision without ship-by-default target
- **Process:** frame → evidence → user-gated conclusion → compound disposition.
  Not-done if open questions / no conclusion. Done is a judgment call once not-done signals clear.
- **Overrides** the feature-track phase table for these units.
- Optional detail: `planning/research-loop.md` if present.

## Integration / merge policy

**Autonomous local merge is authorized** for `/work:continue` (and standalone
execute→finish) when **all** hold:

1. Review completed with **valid evidence** (method, date, verdict, P1–P3 counts, disposition)
2. Project gates clean
3. Task requirements / plan DoD for the slice met
4. End-of-loop recap includes Review findings & disposition when recap applies

Then: **merge to main locally**, compound (or `compound: none — <reason>`), advance NEXT —
**do not** stop for merge confirmation.

Still **stop** when: review missing/invalid, gates red, genuine judgment call, doubt about DoD,
or push/PR needed. **Pushing and opening PRs remain user-initiated.**

### Automation overlay (optional)

When an **unattended / always-PR agent** works this repo, it may apply a **stricter integrate
path** (open PR; stop at merge/E-MERGE; no silent local merge) without changing the phase
dialect. Human continue keeps the local-merge defaults above. Record overlay on the run when
used. Process detail: @work `references/approval-boundaries.md`.

## Agent collaboration (HITL / session drive)

Process contract for how agents present work and ask for decisions — complements user-space
**personify** (voice/prose). Prefer these in workflow loops even when personify is thin.

- **Lead with the answer.** Decision / result / action first; reasoning only when needed or asked.
- **Direct by default.** Green light means act — do not re-confirm routine work.
- **Consultative where it counts.** Confirm first only when hard to reverse, outward-facing, or
  high-leverage.
- **Always recommend.** Options include your pick and the deciding tradeoff. Bare menus are not
  acceptable.
- **Ask once, then stop.** One line; no "your call" / "not mine to make."
- **Caveats once.** Real risk, plain, one time — then move on.
- **Evidence on request, not by default.** Have `file:line` / tests / git ready; do not pre-dump
  unless load-bearing.

## Orientation / queue

- Primary NEXT SoT: `planning/roadmap.md` (or top-level handoff pointer) when multi-unit
- PM queue (only when NEXT empty): issues with label `work:claimable` AND state in {Todo, In Progress} AND assignee = me — order priority then updatedAt;
  **never invent** if zero matches; multi-match → hard_stop_choice with named list
