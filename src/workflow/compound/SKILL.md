---
name: workflow:compound
description: Capture durable knowledge from any engineering work — debugging solutions, refactors, features, design decisions, reusable patterns — so each unit of work compounds the next. Stewardship (prune + yield + memory) is /workflow:maintain; --maintain is a compat shim.
argument-hint: "[context about what was solved] | --maintain → /workflow:maintain (compat)"
user-invocable: true
---

# Knowledge Capture and Compounding

Compounding is about making **every unit of engineering work make subsequent work easier** — not just debugging. A solved bug, a refactor that revealed a cleaner structure, a feature that established a reusable pattern, a hard-won design decision: all of it is durable knowledge worth capturing. Debugging solutions are one important case, not the whole job. Whenever you finish non-trivial work and think "the next person (or the next me) would save real time knowing this," compound applies — regardless of whether anything was ever broken.

**Primary job:** **Capture** durable knowledge from recently completed work and route it via a
**deterministic gate** to the right home (shared memory entry/solution, ADR, personify,
AGENTS.md, or harness-local memory).

**Stewardship** (planning prune check, run yield, memory quality audit) lives on
**`/workflow:maintain`**. Do not conflate capture with plant hygiene.

## Mode Detection

Parse `$ARGUMENTS` to determine mode:

| Input Pattern | Mode | Action |
|---|---|---|
| `--maintain` or any `--maintain --…` flags (`--level`, `--focus`, `--migrate-solutions`) | **Compat → maintain** | Run **`/workflow:maintain`** with the same flags (memory-scoped). Prefer telling the user the primary command is `:maintain`. |
| Any other input or empty | Capture | Capture durable knowledge from recent work |

`--maintain` remains **on-demand** via the shim (runs maintain immediately). Cadence offers on
*capture* invocations only soft-point at `/workflow:maintain` — see [Maintain Due Check](#maintain-due-check-capture-and-bare-compound).

---

# Shared project memory (L3-shared)

Team-shared, git-committed agent working knowledge lives under:

```text
.agent-tools/memory/
  MEMORY.md                 # Entries index (full one-liners); Solutions = pointer only
  state.yml                 # Cadence + last maintain summary
  entries/<slug>.md         # pattern | gotcha | lesson | process
  solutions/<category>/<slug>.md   # debugging post-mortems
```

If this tree is missing, run `/workflow:setup` (or create it during capture/maintain with user confirmation). Do **not** write product docs under `docs/solutions/` for new captures.

**Non-goals for this tree:** ADRs, CONTRIBUTING/gate matrices, Codex/domain docs, planning scratch, personify voice, secrets.

**Primitives reference:** @workflow (`references/memory-primitives.md`).

---

# Capture Mode

## Purpose

**Why "compound"?** Each captured insight compounds your team's knowledge:
- First time working it out: Research / design / debugging (30+ minutes)
- After capturing: Quick lookup or reuse (2-3 minutes)
- Knowledge compounds over time

## Deterministic routing gate (required)

Classify **before** writing. Apply steps **in order**. Do not skip steps or substitute "judgment only" for a failed gate.

### Step 0 — Preconditions

- [ ] **Work is settled** — fix landed, refactor merged, or decision made
- [ ] **It holds up** — confirmed working / you'd reuse the pattern
- [ ] **Non-trivial** — not typos, obvious fixes, or restating what the code already makes plain

If unmet, ask: "Is this work settled and worth capturing for next time?"

### Step 1 — Shape

| Shape | Route |
|-------|--------|
| **Debugging solution** (root-caused bug; build/test/runtime failure; perf/security fix with investigation narrative) | `.agent-tools/memory/solutions/<category>/<slug>.md` |
| **Architecture / design decision** (chose X over Y; convention in force) | `docs/decisions/` (rewrite-in-place). If the *reason it changed* is a reusable lesson → also an `entries/` lesson (Step 2–4) |
| **Personify scope** (voice, interpersonal style, how to talk to the user) | `/personify` path — **not** technical memory |
| **Pattern / technique / gotcha / process invariant** | Continue to Step 2 (applicability) |
| **Process failure mode** (thrash, theater review, repeated rework — reusable operating lesson) | `type: process` entry under L3-shared when project-wide; **do not** edit skills here |

A single unit of work may produce **more than one** artifact (e.g. solution + pattern). Route each independently.

**Corpus self-improvement:** memory captures process *lessons*. Changing workflow/swarm skill
text happens only in the **skill source** via **`/skills:evolve`** when installed (detect →
propose → validate → present), fed by run-ledger evidence and conversation signals. Consumer
projects keep process entries and escalate upstream — compound never invents skill diffs.

### Step 2 — Applicability (non-solution shapes)

| Applicability | Destination |
|---------------|-------------|
| **Project-wide** — any contributor or harness on this repo should know it | L3-shared: `.agent-tools/memory/entries/<slug>.md` + one line in `MEMORY.md` |
| **Personal / collab micro-style** that is user-global | L1 (`~/.claude/CLAUDE.md` or global memory) and/or personify — not project entries |
| **Machine-only** (host paths, locked `op`, local tool quirks) | L3-local harness memory only |
| **Session / ticket-ephemeral** (run IDs, closed-ticket narrative without a durable invariant) | Do not capture; or distill one invariant first, then re-run the gate |

### Step 3 — Overlap and safety gates (block full-body shared write)

Before writing to `entries/` or promoting into shared memory:

| Condition | Action |
|-----------|--------|
| Restates a **current architectural decision** | Link the ADR; do **not** promote the decision body into memory |
| Restates **CONTRIBUTING / gates / command matrix** | Link CONTRIBUTING; one-line reminder max |
| **Near-duplicate** of an existing `entries/` file | Revise the existing entry; do not create a second |
| Contains **secrets**, passwords, account IDs, raw credentials | **Block.** Suggest runbook with placeholders / secret refs only |
| Belongs in **personify** | Redirect; do not write technical entry |
| Always-load rule every agent must see | Prefer a short **AGENTS.md** bullet + optional entry for depth — do not bloat AGENTS with full essays |

Light check only: skim AGENTS.md, CONTRIBUTING.md (if present), `docs/decisions/` titles/index, existing `entries/`. Deep doc consistency is `/workflow:audit`.

### Step 4 — Write rules

1. Ensure `.agent-tools/memory/` exists (scaffold via setup conventions if needed).
2. **Solutions** → write using `templates/solution.md`; categories in `references/debug-agent-panel.md`. Do **not** add every solution to `MEMORY.md` (index is entries-only + a solutions pointer).
3. **Entries** → frontmatter + body with **Why** and **How to apply**; add exactly one index line in `MEMORY.md`.
4. **No full-body dual-write.** Project-wide content goes to L3-shared only. Do not also write the full text into Claude/Codex auto-memory. Optional: thin L3-local pointer to the shared path if the harness needs a stub.
5. If L3-shared tree is missing and user declines scaffold, fall back to L3-local with an explicit note that shared memory is uninitialized.
6. Legacy `docs/solutions/`: **never** write new files there. If it still has content, soft-warn once and point at `--maintain --migrate-solutions`.
7. **Docs promote (optional, user-gated):** when an entry is stable product/architecture knowledge
   (not a ticket diary), offer promote to committed docs — see Step 5.

### Step 5 — Promote L3 → durable docs (OpenWiki-lite)

L3-shared is **agent working knowledge**. Human+agent durable product corpus lives under `docs/`
(or the project’s domain layer). Promotion is **not** automatic on every capture.

**Promote when all hold:**

- Entry applied successfully **≥2 times** or linked from an ADR / shipped design, **or** user asks
- Content is stable (not a one-off thrash note)
- Shape is architecture, operating model, or product invariant — not a raw debug log

**Promote procedure:**

1. Propose target path (default `docs/` or `docs/design/` / `docs/research/` per content; never
   `docs/solutions/` for new material).
2. Distill: rewrite for humans+agents; strip ticket IDs unless load-bearing; link ADR if any.
3. **User approval** before write.
4. Write docs page; set entry frontmatter `promoted_to: <path>` and keep a **thin** L3 entry or
   one-line MEMORY pointer to the docs path (avoid full dual-body).
5. Do not delete the lesson without leaving a pointer.

**Do not promote:** secrets, process thrash that should become an evolve seed only, pure
personify voice, planning scratch.

### Entry frontmatter

```yaml
---
name: <slug>
description: <one-line, actionable>
type: pattern | gotcha | lesson | process
applicability: project
related: []          # optional: ADR paths, solution paths, code paths, run_ids
promoted_at: null    # set when promoted from harness-local
promoted_to: null    # docs path when promoted L3 → durable docs
source_harness: null # optional: claude | codex | factory | …
---
```

### MEMORY.md shape

```markdown
# Project memory index

## Entries
- [Title](entries/<slug>.md) — one-line description
…

## Solutions
Debugging post-mortems live under `solutions/<category>/`. Search by `symptoms` / `tags` in frontmatter; browse by category. Do not enumerate every solution here.
```

Soft budget for the Entries section: warn ~120 lines, force extract/consolidate before ~150. Solutions section stays a short pointer.

---

## User Input

```text
$ARGUMENTS
```

## Invocation Modes

### 1. Session Boundary (Auto from Execute)
```bash
/workflow:compound "Fixed N+1 query in brief generation"
```

### 2. On-Demand
```bash
/workflow:compound
```

### 3. With Context Hint
```bash
/workflow:compound "resolved circular dependency in auth module"
```

## Maintain Due Check (capture and bare compound)

Before capture work (not when args already shim to `/workflow:maintain`):

1. Load due rules from @workflow `maintain/references/cadence.md` (or read
   `.agent-tools/memory/state.yml` with the same formula).
2. If **due**: soft-prompt stewardship — offer **`/workflow:maintain`** now / snooze 3d /
   skip once. Do **not** inline the memory audit on capture.
3. Never block capture if the user declines.
4. On-demand `--maintain` shims to `:maintain` and ignores the interval.

## Undocumented Solution Surfacing

Optional before capture: if scanning harness history for uncaptured work, **load**
`references/undocumented-surfacing.md` (uses @workflow `references/conversation-analysis.md`).

## Parallel Analysis (debugging-solution path only)

For patterns, decisions, and gotchas headed to `entries/` / ADR / AGENTS.md, skip multi-agent fan-out:
capture the insight, alternatives, and when it applies, then index.

For **debugging solutions**, **load** `references/debug-agent-panel.md` and run the specialized agents
(context, solution extract, related docs, prevention, category) before writing the solution doc.

## Output Document (debugging-solution path)

Create `.agent-tools/memory/solutions/<category>/<slug>.md` using **`templates/solution.md`**
(load that template; fill from investigation). Categories are listed in `references/debug-agent-panel.md`.

## Integration Points

### With /workflow:execute

Compound is prompted at session boundaries:

```markdown
This session you solved: [context from session]
Document this for future reference?
1. Yes - create documentation now
2. No - skip
3. Note for later - add to session notes
```

### With Existing Knowledge

Link new docs to related content; update `MEMORY.md` for entries; tag solutions for discovery.

### With AGENTS.md

Only for always-load rules. Prefer shared memory for depth; keep AGENTS thin.

### With /skills:evolve

When capture surfaces a **skill corpus gap** (continue mis-route, missing gate, track bug),
record the process lesson. If `/skills:evolve` is available (skill source), point there; else
point upstream to the skill source. Compound **never** applies skill patches itself and does
**not** invent a workflow-local improve command.

### With runs ledger

Thrash / rework close may cite `run_id` from `.agent-tools/runs/` in a process entry’s
`related:` field. Prefer `type: process` with symptoms + hypothesized skill gap + candidate
skill paths (portable seed fields; see @workflow `references/runs-ledger.md`). Do not patch
skills here. Line yield and cadence live on **`/workflow:maintain`**.

### With docs promote

Stable architecture/product entries may promote to `docs/` (Step 5). `/workflow:maintain`
(memory job) may flag promote candidates (see @workflow `maintain/references/memory.md`).


## Success Output

```markdown
## Knowledge Documented

**File created:**
`.agent-tools/memory/solutions/[category]/[slug].md`
  — or —
`.agent-tools/memory/entries/[slug].md` (+ MEMORY.md line)
  — or —
`docs/decisions/...` / AGENTS.md / personify as routed

**Summary:**
- Shape: [solution | pattern | gotcha | lesson | process | decision]
- One-line: […]

**Next time:**
Search `entries/` / `MEMORY.md` or `solutions/<category>/` by symptoms/tags
```


## When to Compound / Skip

**Always capture:** non-obvious debugging solutions; environment/integration/perf/security lessons;
reusable patterns; non-obvious design decisions (+ lessons when decisions change); cross-cutting
gotchas and invariants.

**Skip:** typos; obvious fixes; one-offs; knowledge already well-documented or plain in code; trivial config.

## Quality Checklist

**Solutions:**
- [ ] Problem, symptoms (searchable), root cause, reproducible solution
- [ ] Prevention, tags, related links, accurate code

**Entries:**
- [ ] Clear name/description/type
- [ ] Why + How to apply
- [ ] MEMORY.md one-liner present
- [ ] Overlap gates passed; no secrets


## Maintain shim

When mode detection routes to `--maintain` (any maintain flags), **do not** run capture.
Hand off to **`/workflow:maintain`** with the same flags — load `@workflow:maintain` SKILL.md
and its references. Pointer only: `references/maintain.md`.
