# Context compact protocol

**Load when:** a **mid-item** breakpoint needs a clean window — dumb-zone / trajectory thrash;
slice or phase complete with **more work remaining on the same unit**; trajectory-changing
correction; or polluted chat before the next segment of the **same** workstream.

**Goal:** reclaim conversation context **after** durable steering is on disk, then
**continue the same workstream** (typically via the execute loop or `/workflow:continue` on
the same unit) without replaying tool noise.

Project-agnostic — planning-root / unit paths only (@workflow `references/planning-root.md`).

**Related norms:** dumb-zone bands and IC *content* fields —
@workflow `references/context-engineering.md`. This file owns **control flow** (when to
compact vs hand off, reclaim, resume).

## Mid-item compact vs end-of-item handoff (critical)

| Situation | Compact? | What to do |
|-----------|----------|------------|
| **Mid-item** — unit still `in_progress`; plan/slice work remains; breakpoint is for context | **Yes** — full protocol through RESUME | WRITE IC → RECLAIM window → **continue same phase/stream** |
| **End-of-item** — unit done / ready for review·integrate·compound·session end with no more execute work | **No** | Session handoff only (update session-state, commit, compound offer, handoff summary). Do **not** run this protocol as a substitute for handoff. |

**Anti-pattern:** Mid-item WRITE of Intentional Compaction, then **stop as if the session were
over**, without reclaiming the window and without continuing the workstream. That is a
**failed** mid-item compact — preparation without the point of the protocol.

**Anti-pattern:** Running host compact at end-of-item “because the window is big” when the
correct ritual is handoff. End-of-item does not require compact.

## Hard rules

1. **Write before reclaim.** Never compact or clear the thread until Intentional Compaction
   (and plan status, when applicable) is written.
2. **Files beat chat.** After reclaim, steering comes from disk (`resume_loads`), not from
   pre-compact tool dumps.
3. **Mid-item success = reclaim + continue.** Soft “Resume card and stop forever” is only a
   **fallback** when the host cannot compact; the operator or next turn must still reclaim
   then continue — not abandon the unit.
4. **Do not invent host tools.** If the host documents conversation compact with focus text
   (e.g. `/compact …`), use that path for mid-item reclaim. If the agent cannot *invoke*
   slash commands, **instruct the user to run the exact command** with `compact_focus`, then
   on the next turn run RESUME (do not skip reclaim).
5. **Do not name a skill `compact`.** Built-in host commands win / collide.
6. **No product-specific paths or ticket schemes** in this protocol text.

## Steps (run end-to-end for mid-item)

### 0. Classify breakpoint

- More work remains on this unit / phase → **mid-item** → continue below.  
- Unit complete or session ending with no further execute → **end-of-item** → handoff
  protocol only; **exit this file**.

### 1. FREEZE

Stop new exploration, speculative edits, and additional MCP/tool dumps. Finish only what is
required for an honest snapshot.

### 2. WRITE (durable)

Update unit artifacts (paths relative to the **unit** directory):

1. **`session-state.md`** — Current Focus; **Intentional Compaction** (fields below).  
2. **`implementation-plan.md`** — checkboxes; short **Status after phase N** if approach
   diverged.

#### Intentional Compaction fields (content)

Match @workflow `references/context-engineering.md` › Mid-phase intentional compaction:

```markdown
### Intentional Compaction — [timestamp]

- **Goal (unchanged / revised):** …
- **Approach:** …
- **Done so far:** …
- **Current failure or next step:** …
- **Key files:** …
- **Tests / verification last green:** …
- **Do not re-open:** [dead ends]
```

#### Operational fields

```markdown
- **compact_focus:** [3–8 lines — unit id, phase/NEXT, last green, constraints, dead ends]
- **resume_loads:** ordered paths, e.g.
  1. `<unit>/session-state.md` (latest IC only)
  2. `<unit>/implementation-plan.md`
  3. `<unit>/codebase-research.md` (if present)
  4. `<unit>/design-discussion.md` (if design still open)
```

**Latest-IC-wins:** newest IC block is the resume surface; do not require re-reading full
history.

### 3. EMIT

Derive `compact_focus` from NEXT / constraints. Keep it short enough for host compact
instructions.

### 4. RECLAIM (window)

| Mode | When | Behavior |
|------|------|----------|
| **harness_compact** | Host has conversation compact **with focus/keep text** (see agent quick-refs) | **Required for mid-item** on that host. After WRITE: invoke compact with `compact_focus`, **or** output the exact user command (e.g. `/compact <compact_focus>`) as a **blocking next step**, then proceed to RESUME on the following turn. Do **not** offer “soft-stop only” as the primary outcome. |
| **soft_compact** | Host has **no** documented focus-compact, or compact truly cannot run | Emit **Continue card** (below): durable paths + instruction that the **operator or next session** must open a clean window (new session / clear) and run `/workflow:continue` or execute continue on the **same unit**. Do not pretend the window was reclaimed in-thread. |

**Toxic trajectory** (apology loops): prefer a hard clear/new session after WRITE, then
RESUME via continue — still mid-item continue, not end-of-item handoff theater.

### 5. RESUME (same workstream)

After reclaim (harness compact completed, or new/clean session after soft path):

1. Load **only** `resume_loads` (+ thin phase skill procedure).  
2. Restate **NEXT** from the **latest** IC.  
3. **Continue the same phase** — execute loop, or `/workflow:continue` / execute continue on
   the same unit. Do **not** re-run portfolio discovery unless the unit is unclaimed.  
4. Do **not** re-dump pre-compact tool noise into the parent window.

Mid-item is **incomplete** until this step is in progress or complete — not when WRITE alone
finishes.

## Continue card (soft_compact / blocked harness — mid-item only)

When reclaim cannot finish in-thread, present this and **pause only until a clean window
exists** — the workstream is **not** closed:

```markdown
## Context compact — continue (mid-item)

**Breakpoint:** mid-item (work remains) — not end-of-item handoff.

**Durable steering written:**
- Unit: `<planning-root>/<unit>/`
- Latest IC: `session-state.md`
- Plan status: [updated / unchanged]

**compact_focus** (paste into host compact if available):
> …

**resume_loads** (read in order after reclaim):
1. …
2. …

**Required next (same workstream):**
1. Reclaim window: run host compact with the focus above, **or** start a **new** session
   in the same repo cwd (soft hosts).
2. Then: `/workflow:continue` (or `/workflow:execute continue`) on this unit — load
   resume_loads, restate NEXT, keep executing.

**Do not:** treat this card as end-of-item handoff; do not invent portfolio NEXT; do not
replay pre-compact dumps.
```

## Adapters (host capability)

| Host class | Mid-item reclaim |
|------------|------------------|
| Documents `/compact` (or equivalent) **with focus text** | **harness_compact** required — invoke or exact user command, then RESUME |
| No focus-compact | **soft_compact** Continue card → new/clean session → `/workflow:continue` |

Agent capability rows: `@skills` `references/agents/`. Do not guess slash names.

## Call sites

| Skill | When |
|-------|------|
| **execute** (primary) | Mid-phase triggers while tasks remain; lost-context recovery mid-unit |
| **continue** | After reclaim, claim/`in_progress` resume from latest IC; re-enter protocol if thrash mid-drive |
| **Session handoff** (execute boundary) | End-of-item / user ending session — **not** this protocol |

Discovery-heavy skills should prefer **subagent digests** over parent compact when the parent
is not mid-implement.

## Anti-patterns

- Mid-item IC write + stop without reclaim + continue  
- End-of-item host compact instead of handoff  
- Compacting before writing IC  
- “I’ll forget that” without disk write  
- Soft path that keeps editing in the polluted turn  
- Treating auto-compact at high % utilization as a substitute for WRITE + intentional focus  
- Product- or repo-specific examples in protocol text  

## Related

| Topic | Path |
|-------|------|
| Dumb zone, IC field norms | `context-engineering.md` |
| Planning root | `planning-root.md` |
| Execute | `@workflow:execute` |
| Drive / resume | `@workflow:continue` |
