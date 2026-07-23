# Context compact protocol

**Load when:** dumb-zone or trajectory triggers fire; a slice/sub-issue completes with more
work remaining; a trajectory-changing user correction lands; a phase gate needs a clean
window before the next segment; or resume after thrash when the chat is polluted.

**Goal:** reclaim conversation context **after** durable steering is on disk, then continue the
**same** workstream without replaying tool noise. Project-agnostic — use planning-root / unit
paths only (see @workflow `references/planning-root.md`).

**Related norms:** dumb-zone bands, IC *content* fields, and when compaction is mandatory —
@workflow `references/context-engineering.md`. This file owns **control flow** (reclaim +
resume), not a second copy of product design craft.

## Hard rules

1. **Write before reclaim.** Never compact or clear the thread until Intentional Compaction
   (and plan status, when applicable) is written.
2. **Files beat chat.** After reclaim, steering comes from disk (`resume_loads`), not from
   pre-compact tool dumps still in memory.
3. **Soft path always works.** Do not invent a host tool or slash command that is not
   documented for this agent. If reclaim cannot run in-thread, use **soft_compact**.
4. **Do not name a skill `compact`.** Many hosts reserve `/compact` as a built-in; a skill
   with that name collides or is shadowed.
5. **No product-specific paths or ticket schemes** in this protocol — only unit planning
   artifacts under the resolved planning root.

## Steps (run end-to-end)

### 1. FREEZE

Stop new codebase exploration, speculative edits, and additional MCP/tool dumps. Finish only
what is required to write an honest snapshot (e.g. note last green test command already run).

### 2. WRITE (durable)

Update unit artifacts under the planning root (paths relative to the **unit** directory):

1. **`session-state.md`** — Current Focus; Last Session Summary if useful; **Intentional
   Compaction** snapshot (fields below).  
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

#### Operational fields (emit with the snapshot)

```markdown
- **compact_focus:** [3–8 lines — what a summarizer or host compact must keep: unit id,
  phase/NEXT, branch tip or last green, constraints, dead ends to avoid]
- **resume_loads:** ordered paths the next turn must read, e.g.
  1. `<unit>/session-state.md` (latest IC only for steering)
  2. `<unit>/implementation-plan.md`
  3. `<unit>/codebase-research.md` (if present)
  4. `<unit>/design-discussion.md` (if design still open)
```

**Latest-IC-wins:** the newest Intentional Compaction block is the resume surface. Older
blocks are history — do **not** require re-reading the full compaction history to continue.
Prefer replacing or clearly labeling the latest block rather than unbounded append-only growth.

### 3. EMIT

Derive `compact_focus` from the IC **Current failure or next step** / NEXT and constraints.
Keep it short enough to pass as host compact instructions or a soft Resume card body.

### 4. RECLAIM

| Mode | When | Behavior |
|------|------|----------|
| **harness_compact** | Host documents an in-session conversation compact that accepts **focus / keep** instructions, and you can invoke it in this session | **One-gate** unless the user already ordered compact: offer compact & continue / soft-stop only / keep going. On approve, invoke host compact with `compact_focus` as the keep-instructions. |
| **soft_compact** | Default; unknown host; compact not invocable; user chose soft-stop | Emit the **Resume card** (below), **stop the turn**. Do not claim the window was reclaimed. |

**Toxic trajectory** (apology loops, repeated failed corrections): prefer soft_compact or a
full clear/new session over a weak in-thread summary — still only after WRITE.

### 5. RESUME

After successful harness compact **or** on the first turn of a new/soft session:

1. Load **only** `resume_loads` (plus minimal skill procedure for the current phase).  
2. Restate **NEXT** from the **latest** IC.  
3. Continue the **same** phase/stream (execute loop, continue phase machine, etc.) — do not
   re-run portfolio discovery unless the unit is unclaimed or path is not established.  
4. Do **not** re-dump large prior tool results into the parent window.

## Resume card (soft_compact template)

Present to the user (and stop):

```markdown
## Context compact — resume card

**Why:** [dumb-zone / slice complete / thrash / phase gate]

**Durable steering written:**
- Unit: `<planning-root>/<unit>/`
- Latest IC: in `session-state.md`
- Plan status: [updated / unchanged]

**compact_focus** (for host `/compact` or next-session paste):
> …

**resume_loads** (read in order after reclaim):
1. …
2. …

**Continue same workstream:**
- Same session after host compact: re-read resume_loads, then continue the phase.
- New session: `/workflow:continue` or `/workflow:execute continue` with the unit path
  (or claim via continue if that is the project drive entry).

**Do not:** replay pre-compact search dumps; reopen dead ends listed in the IC.
```

## Adapters (host capability)

Portable rule: **if the agent quick-ref or host docs list a conversation-compact command with
optional focus text, you may use harness_compact; otherwise soft_compact only.**

Do not guess slash commands. Agent capability notes live under `@skills`
`references/agents/` (compact row). Refresh those refs when host behavior changes — do not
fork long host manuals into this protocol.

## Call sites (who runs this)

| Skill | When |
|-------|------|
| **execute** (primary) | Mid-phase triggers; lost-context recovery |
| **continue** | Resume of `in_progress` unit (load latest IC); optional full protocol when dumb-zone / thrash fires mid-drive |
| **refine / plan / review** | Optional at heavy phase gates only — same protocol, do not re-embed |

Discovery-heavy skills (audit, large search) should prefer **subagent digests** into the parent
rather than compacting the parent first.

## Anti-patterns

- Compacting before writing IC  
- “I’ll forget that” without disk write  
- Soft path that still continues heavy edits in the same polluted turn  
- Requiring the full session-state history to resume  
- Product- or repo-specific examples in protocol text  
- Treating auto-compact at high % utilization as a substitute for this protocol  

## Related

| Topic | Path |
|-------|------|
| Dumb zone, IC field norms, research/design craft | `context-engineering.md` |
| Planning root resolution | `planning-root.md` |
| Execute loop | `@workflow:execute` |
| Drive / resume | `@workflow:continue` |
