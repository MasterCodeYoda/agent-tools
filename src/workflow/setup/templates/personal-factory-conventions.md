# Project Workflow Conventions

> Personal factory profile — sparse overlay. Maintained by `/workflow:setup`.
> Any section omitted keeps the skill’s built-in default.

## Requirements source

pm (linear)
<!-- or: file -->

## Work tracks

### Default feature track

brainstorm → refine → plan → execute → review → finish → compound

### micro

- **When:** clear bug / small enhancement / docs / chore; issue or paste is the plan; no new
  public contract; user `micro`|`direct`|`small` — see @workflow `references/tracks.md`
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

**Autonomous local merge is authorized** for `/workflow:continue` (and standalone
execute→finish) when **all** hold:

1. Review completed with **valid evidence** (method, date, verdict, P1–P3 counts, disposition)
2. Project gates clean
3. Task requirements / plan DoD for the slice met
4. End-of-loop recap includes Review findings & disposition when recap applies

Then: **merge to main locally**, compound (or `compound: none — <reason>`), advance NEXT —
**do not** stop for merge confirmation.

Still **stop** when: review missing/invalid, gates red, genuine judgment call, doubt about DoD,
or push/PR needed. **Pushing and opening PRs remain user-initiated.**

## Visual plan approval

- **Policy:** never

## Orientation / queue

- Primary NEXT SoT: `planning/roadmap.md` (or top-level handoff pointer) when multi-unit
- PM queue (only when NEXT empty): issues with label `workflow:claimable` (or `plant:claimable`
  legacy) AND state in {Todo, In Progress} AND assignee = me — order priority then updatedAt;
  **never invent** if zero matches; multi-match → hard_stop_choice with named list
