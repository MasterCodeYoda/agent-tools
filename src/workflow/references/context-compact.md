# Context compact protocol

**Load when:** a **mid-item** breakpoint needs a clean window — dumb-zone / trajectory thrash;
slice or phase complete with **more work remaining on the same unit**; trajectory-changing
correction; or polluted chat before the next segment of the **same** workstream.

**Goal:** write durable steering on disk, **reclaim** conversation context (default: clean
session), then **continue the same workstream** via `/workflow:continue` or execute continue
on that unit — without replaying tool noise.

Project-agnostic — planning-root / unit paths only (@workflow `references/planning-root.md`).

**Related norms:** dumb-zone bands and IC *content* fields —
@workflow `references/context-engineering.md`. This file owns **control flow**.

**Automation boundary:** This protocol fully automates the **durable checkpoint** (WRITE) and
specifies the reclaim/continue contract. **Invoking** host `/clear`, `/new`, or `/compact` is
usually a **user or outer orchestrator** action (agents cannot reliably run slash commands).
Optional **Stop / SessionStart hooks** (see `hooks/reclaim-hooks.md`) detect the signal and
coach or re-seed; they do **not** claim full auto-reclaim. Full automation belongs to an
orchestration layer outside this skill corpus.

## Mid-item reclaim vs end-of-item handoff

| Situation | Reclaim protocol? | What to do |
|-----------|-------------------|------------|
| **Mid-item** — unit still has work; breakpoint is for context | **Yes** — full protocol through RESUME | WRITE IC → RECLAIM → continue same unit |
| **End-of-item** — unit done / session end with no more execute | **No** | Session handoff only (state, commit, compound, handoff summary) |

**Anti-pattern:** Mid-item WRITE then stop as if the session were over (IC-only “prepared”).
That is incomplete — reclaim + continue are required.

**Anti-pattern:** Host compact at end-of-item instead of handoff.

## Hard rules

1. **Write before reclaim.** Never clear/compact until Intentional Compaction (and plan status
   when applicable) is written.
2. **Files beat chat.** After reclaim, steering comes from disk (`resume_loads`).
3. **Mid-item success = reclaim + continue.** Not WRITE alone.
4. **Default reclaim = clean session** (`/clear` or `/new` per host) — portable and aligned
   with “files beat chat.” Optional **host compact** only when the user prefers stay-in-thread.
5. **Do not invent host tools.** Emit the **exact** host command; do not guess slash names.
6. **Do not name a skill `compact`.** Built-ins win / collide.
7. **Emit the machine signal** after WRITE so hooks/orchestrators can detect mid-item reclaim.
8. **No product-specific paths** in this protocol text.

## Steps (mid-item only)

### 0. Classify

- Work remains on this unit → mid-item → continue below.  
- Unit complete or user ending with no further execute → **end-of-item handoff**; exit this file.

### 1. FREEZE

Stop exploration and speculative edits. Finish only what is needed for an honest snapshot.

### 2. WRITE (durable) — fully agent-owned

Update unit artifacts:

1. **`session-state.md`** — Current Focus; **Intentional Compaction** (fields below).  
2. **`implementation-plan.md`** — checkboxes; **Status after phase N** if approach diverged.

#### IC content fields

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
- **compact_focus:** [3–8 lines — unit, NEXT, last green, constraints]
- **resume_loads:** ordered relative paths
  1. `<unit>/session-state.md` (latest IC)
  2. `<unit>/implementation-plan.md`
  3. `<unit>/codebase-research.md` (if present)
  4. …
```

**Latest-IC-wins** for resume.

### 3. EMIT signal + host reclaim command

#### Machine signal (required, last assistant message)

Include exactly one fenced block (hooks parse this):

````markdown
```yaml
workflow_reclaim:
  kind: mid-item
  unit: <planning-root-relative unit dir>
  reclaim: clean-session   # or host-compact
  continue: workflow:continue
  host_command: /clear     # host-specific: /clear | /new | /compact <focus>
```
````

| Field | Meaning |
|-------|---------|
| `kind` | Always `mid-item` for this protocol |
| `unit` | Unit dir relative to repo / planning root |
| `reclaim` | `clean-session` (default) or `host-compact` |
| `continue` | `workflow:continue` or `workflow:execute continue` |
| `host_command` | Exact string the user/orchestrator should run |

#### Host command defaults

| Host class | Default `reclaim` | Typical `host_command` |
|------------|-------------------|------------------------|
| Claude Code | clean-session | `/clear` |
| Grok Build | clean-session | `/new` (alias `/clear`) |
| OpenCode | clean-session | new session / clear session (host UI or docs) |
| Optional stay-in-thread | host-compact | `/compact <compact_focus text>` (Grok/Claude when preferred) |

Also present a short human **Continue card** (below).

### 4. RECLAIM

| Mode | When | Who runs it |
|------|------|-------------|
| **clean_session** | **Default** mid-item | User or outer orchestrator runs `host_command` (`/clear` or `/new`). Agent cannot assume it ran. |
| **host_compact** | User prefers in-thread summary | User/orchestrator runs `/compact` with `compact_focus`. Lossy; still RESUME from disk. |

After WRITE + signal, **pause for reclaim** unless an outer system already cleared the window.
Do not continue heavy mid-item work in the pre-reclaim polluted thread.

### 5. RESUME (same workstream)

After clean session or host compact (new turn / SessionStart after clear):

1. Load **only** `resume_loads` (+ thin phase skill).  
2. Restate **NEXT** from latest IC.  
3. **Continue same unit** — `/workflow:continue` or execute continue; no portfolio rediscovery
   unless unclaimed.  
4. Do not re-dump pre-reclaim tool noise.

## Continue card (human-facing)

```markdown
## Context reclaim — mid-item (not end-of-item handoff)

**Durable steering written** under: `<unit>/session-state.md` (latest IC).

**1. Reclaim window** (run exactly):
` <host_command> `

**2. Continue same workstream:**
`/workflow:continue` (or `/workflow:execute continue`) — read resume_loads, restate NEXT.

**Do not:** treat this as unit complete; do not invent portfolio NEXT.
```

## Call sites

| Skill | When |
|-------|------|
| **execute** | Mid-phase triggers while tasks remain |
| **continue** | Resume after reclaim; re-enter protocol if thrash mid-drive with work remaining |
| **Session handoff** | End-of-item only — not this protocol |

Optional hooks: **load** `hooks/reclaim-hooks.md`.

## Anti-patterns

- Mid-item IC + stop without reclaim + continue  
- End-of-item compact instead of handoff  
- Compacting/clearing before WRITE  
- Treating auto-compact at high % utilization as this protocol  
- Claiming the agent “ran” `/clear` without user/orchestrator action  
- Skill named `compact`  

## Related

| Topic | Path |
|-------|------|
| IC content / dumb zone | `context-engineering.md` |
| Reclaim hooks (optional) | `hooks/reclaim-hooks.md` |
| Execute / continue | `@workflow:execute`, `@workflow:continue` |
