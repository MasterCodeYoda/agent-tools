---
name: workflow:compound
description: Capture durable knowledge from any engineering work — debugging solutions, refactors, features, design decisions, reusable patterns — and maintain memory quality so each unit of work compounds the next
argument-hint: "[context about what was solved] | --maintain [--level global|project|memory|shared|local] [--focus staleness|accuracy|scope|gaps] [--migrate-solutions]"
user-invocable: true
---

# Knowledge Capture and Compounding

Compounding is about making **every unit of engineering work make subsequent work easier** — not just debugging. A solved bug, a refactor that revealed a cleaner structure, a feature that established a reusable pattern, a hard-won design decision: all of it is durable knowledge worth capturing. Debugging solutions are one important case, not the whole job. Whenever you finish non-trivial work and think "the next person (or the next me) would save real time knowing this," compound applies — regardless of whether anything was ever broken.

Two modes for managing your team's accumulated intelligence:

- **Capture mode** (default): Capture durable knowledge from recently completed work and route it via a **deterministic gate** to the right home (shared memory entry/solution, ADR, personify, AGENTS.md, or harness-local memory).
- **Maintain mode** (`--maintain`): Audit and refine agent memory quality across the hierarchy; classify harness-local memories for promotion into project-shared memory; optionally migrate legacy `docs/solutions/`.

## Mode Detection

Parse `$ARGUMENTS` to determine mode:

| Input Pattern | Mode | Action |
|---|---|---|
| `--maintain` | Maintain | Full memory quality audit (see Maintain Mode) |
| `--maintain --migrate-solutions` | Maintain + migrate | Full audit **and** legacy `docs/solutions/` migration proposal |
| `--maintain --level global` | Maintain (scoped) | Audit user-global preferences only |
| `--maintain --level project` | Maintain (scoped) | Audit `<repo>/AGENTS.md` / `CLAUDE.md` only |
| `--maintain --level shared` | Maintain (scoped) | Audit `.agent-tools/memory/` only |
| `--maintain --level local` | Maintain (scoped) | Audit harness-local auto-memory only |
| `--maintain --level memory` | Maintain (scoped) | Alias: audit **both** L3-shared and L3-local |
| `--maintain --focus staleness` | Maintain (focused) | Staleness check across levels |
| `--maintain --focus accuracy` | Maintain (focused) | Accuracy verification across levels |
| `--maintain --focus scope` | Maintain (focused) | Scope placement analysis |
| `--maintain --focus gaps` | Maintain (focused) | Gap analysis against codebase |
| Any other input or empty | Capture | Capture durable knowledge from recent work |

`--maintain` is **always on-demand** — it runs immediately. Cadence state only drives soft prompts on *other* compound invocations (see [Maintain Due Check](#maintain-due-check-capture-and-bare-compound)).

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

A single unit of work may produce **more than one** artifact (e.g. solution + pattern). Route each independently.

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
2. **Solutions** → template under [Output Document](#output-document-debugging-solution-path); categories below. Do **not** add every solution to `MEMORY.md` (index is entries-only + a solutions pointer).
3. **Entries** → frontmatter + body with **Why** and **How to apply**; add exactly one index line in `MEMORY.md`.
4. **No full-body dual-write.** Project-wide content goes to L3-shared only. Do not also write the full text into Claude/Codex auto-memory. Optional: thin L3-local pointer to the shared path if the harness needs a stub.
5. If L3-shared tree is missing and user declines scaffold, fall back to L3-local with an explicit note that shared memory is uninitialized.
6. Legacy `docs/solutions/`: **never** write new files there. If it still has content, soft-warn once and point at `--maintain --migrate-solutions`.

### Entry frontmatter

```yaml
---
name: <slug>
description: <one-line, actionable>
type: pattern | gotcha | lesson | process
applicability: project
related: []          # optional: ADR paths, solution paths, code paths
promoted_at: null    # set when promoted from harness-local
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

Before capture work (not when user already passed `--maintain`):

1. Read `.agent-tools/memory/state.yml` if present.
2. If missing, `last_maintain_at` is null, or older than `interval_days` (default **7**):
   - Soft-prompt: maintain is due — **run now** / **snooze 3d** (write `snooze_until`) / **skip once**.
3. Never block capture if the user declines.
4. On-demand `--maintain` ignores the interval and always runs.

## Undocumented Solution Surfacing

Before starting capture, check conversation history for completed work that was never captured. References: @workflow (`references/conversation-analysis.md`)

```
1. Get project root: git rev-parse --show-toplevel
2. Read harness history (e.g. ~/.claude/history.jsonl) — filter entries where "project" starts with project root
3. Group by sessionId
4. For each session, read facets if available
5. Filter for sessions with outcome "fully_achieved" and a meaningful brief_summary
6. Cross-reference against:
   - .agent-tools/memory/solutions/
   - .agent-tools/memory/entries/
   - legacy docs/solutions/ (if still present)
7. Present undocumented work (if any) before proceeding
```

If found, offer select by number / skip / all. If none, proceed.

## Parallel Analysis (debugging-solution path only)

For patterns, decisions, and gotchas headed to `entries/` / ADR / AGENTS.md, skip this fan-out: capture the insight, alternatives, and when it applies, then index.

For **solutions**, launch specialized agents:

### Agent 1: Context Analyzer
Extracts problem type, component, symptoms, errors → YAML frontmatter structure

### Agent 2: Solution Extractor
Steps tried, root cause, working solution, insights

### Agent 3: Related Docs Finder
Searches `.agent-tools/memory/solutions/`, `entries/`, ADRs, similar patterns

### Agent 4: Prevention Strategist
Recurrence avoidance, practices, tests, warning signs

### Agent 5: Category Classifier
Best-fit category, slug, tags

## Debugging-Solution Categories

| Category | When to Use |
|----------|-------------|
| `build-errors/` | Compilation, bundling, dependency issues |
| `test-failures/` | Test suite issues, flaky tests |
| `runtime-errors/` | Exceptions, crashes, unexpected behavior |
| `performance-issues/` | Slow responses, memory leaks, N+1 queries |
| `database-issues/` | Migrations, queries, connection problems |
| `security-issues/` | Vulnerabilities, auth problems |
| `ui-bugs/` | Visual issues, interaction problems |
| `integration-issues/` | API failures, service communication |
| `logic-errors/` | Incorrect behavior, edge cases |

Unknown legacy categories from migrate: map to closest above or `misc/`.

## Output Document (debugging-solution path)

Create `.agent-tools/memory/solutions/<category>/<slug>.md`:

```markdown
---
title: [Descriptive Title]
category: [category-name]
created: [timestamp]
symptoms:
  - [Observable symptom 1]
  - [Observable symptom 2]
tags:
  - [tag1]
  - [tag2]
related:
  - [path/to/related/doc]
---

# [Title]

## Problem

[What went wrong - the observable issue]

**Symptoms:**
- [How the problem manifested]
- [Error messages if any]
- [Observable behavior]

## Investigation

[What was tried during debugging]

### Steps Tried
1. [First approach] - [why it didn't work]
2. [Second approach] - [what was learned]
3. [Approach that worked] - [led to solution]

## Root Cause

[Technical explanation of why the problem occurred]

## Solution

[Step-by-step fix with code examples]

### Code Changes

```[language]
# Before (problematic)
[code that caused the issue]

# After (fixed)
[corrected code]
```

### Implementation Notes
- [Important detail 1]
- [Important detail 2]

## Prevention

[How to avoid this in the future]

### Best Practices
- [Practice 1]
- [Practice 2]

### Warning Signs
- [Early indicator 1]
- [Early indicator 2]

### Related Tests
```[language]
# Test to catch this issue
[test code if applicable]
```

## References

- [Link to PR/commit]
- [Link to related documentation]
- [External resources consulted]
```

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

## The Compounding Philosophy

```
Build -> Test -> Find Issue -> Research -> Improve -> Document -> Deploy
  ^                                                                  |
  └──────────────────────────────────────────────────────────────────┘
         Each cycle builds on documented knowledge
```

### When to Compound

**Always capture:**
- Non-obvious debugging solutions
- Environment/integration/performance/security lessons
- Reusable patterns from refactors/features
- Non-obvious design decisions (+ lessons when decisions change)
- Cross-cutting gotchas and invariants

**Skip:**
- Typos and obvious fixes
- One-offs unlikely to recur
- Knowledge already well-documented or plain in code
- Trivial configuration changes

## Quality Checklist

**Solutions:**
- [ ] Problem, symptoms (searchable), root cause, reproducible solution
- [ ] Prevention, tags, related links, accurate code

**Entries:**
- [ ] Clear name/description/type
- [ ] Why + How to apply
- [ ] MEMORY.md one-liner present
- [ ] Overlap gates passed; no secrets

## Commands to Remember

```bash
# After non-trivial work
/workflow:compound "brief context"

# Audit / promote / clean (on-demand, any time)
/workflow:compound --maintain

# Also migrate legacy docs/solutions/
/workflow:compound --maintain --migrate-solutions

# Search
rg "symptom" .agent-tools/memory/solutions/
rg "gotcha" .agent-tools/memory/entries/
```

---

# Maintain Mode

Activated by `--maintain`. Evaluate memory quality across:

| Level | Location |
|-------|----------|
| **L1 Global** | User-wide prefs (e.g. `~/.claude/CLAUDE.md`, global auto-memory) |
| **L2 Project guide** | `<repo>/AGENTS.md` (and `CLAUDE.md` if not a symlink to AGENTS) |
| **L3-shared** | `.agent-tools/memory/` (`MEMORY.md`, `entries/`, `solutions/`) |
| **L3-local** | Harness auto-memory (e.g. Claude `~/.claude/projects/<hash>/memory/`) |

Produce a refinement **proposal**; apply only after user approval.

**Why maintenance belongs in compound:** You can't compound on stale, duplicated, or harness-siloed memory.

## Maintain Auto-Detection

```
1. L1 — user global prefs existence/size
2. L2 — AGENTS.md / CLAUDE.md
3. L3-shared — .agent-tools/memory/:
   a. MEMORY.md (entries index line count)
   b. entries/*.md count by type
   c. solutions/**/*.md count by category
   d. state.yml (last_maintain_at, interval_days, solutions_migrated_from_docs)
4. L3-local — detect harness roots:
   a. Claude: ~/.claude/projects/*<repo-path-hash>*/memory/ (MEMORY.md + satellites)
   b. Factory: .factory/memories.md, ~/.factory/memories.md if present
   c. Codex: only if memories feature enabled and content present (do not invent)
5. Legacy docs/solutions/ — if present and not migrated, flag for migrate
6. Stack + recent git (30–60d) for gap assessment
7. Total surface area across levels
```

## Maintain Scope Gate

- **Minimal** (< 5 local/shared entry files, MEMORY.md < 50 lines): All tiers automatically
- **Standard** (5–15 files, MEMORY.md 50–150 lines): All tiers automatically
- **Dense** (15+ files OR MEMORY.md > 150 lines OR L3-local > 50 files): Tier 1 all; prompt before Tier 2/3

## Maintain Agent Reasoning Standards

- **Cite evidence on both sides.** Memory `file:line` AND codebase evidence.
- **Check the opposite hypothesis** before declaring stale.
- **Verify before stale** — at least two searches (name + concept).
- **Respect intentional scope** — L1 cross-project prefs are valid.
- **Distinguish outdated from wrong.**
- **Distill on promote** — one invariant per entry; strip ticket narrative; prefer mechanism names over ticket IDs.

## Maintain Three-Tier Analysis

### Tier 1 — Structural Integrity

Spawn parallel agents as needed:

**shared-index-integrity**:
- `MEMORY.md` exists; Entries section lists every `entries/*.md` (orphans)
- Every Entries path in MEMORY.md exists (broken refs)
- No requirement that every `solutions/**` file appears in MEMORY.md
- Entries section soft budget (warn ~120 lines)
- Solutions: valid category dirs, non-empty frontmatter for solution files

**local-index-integrity** (when L3-local present):
- Local MEMORY.md / satellites consistency (Claude 200-line / 25 KB warnings at 160+ / 190+)
- Orphans and broken refs in local index

**frontmatter-and-type-validator**:
- Shared entries: `name`, `description`, `type` ∈ {pattern, gotcha, lesson, process}
- Local Claude-style: accept nested `metadata.type` or top-level `type` ∈ {user, feedback, project, reference} for local only
- Solutions: title/category/symptoms preferred

**scope-placement-analyzer**:
- L1 = user-wide only
- L2 = thin always-load project rules (not a dump of entries)
- L3-shared = project-wide agent working knowledge
- L3-local = personal/machine/session-adjacent — flag project-wide content still only local (**promotion candidates**)
- Duplication across shared and local full bodies

### Tier 2 — Codebase Cross-Reference

**staleness-detector**, **accuracy-verifier**, **gap-detector** — same intent as before, across shared + local.

### Tier 3 — Heuristic Analysis

**contradiction-detector**, **quality-and-actionability-reviewer**, **consolidation-advisor** — shared + local; prefer consolidating into shared when project-wide.

## Applicability classification (L3-local remaining items)

After retire/revise candidates, classify each remaining local memory:

| Class | Meaning | Default action |
|-------|---------|----------------|
| `project-shared` | Any contributor/harness should know it | Propose promote → `entries/` (distilled) |
| `personal` | User collab prefs | Keep local or route L1/personify |
| `machine` | Host-specific | Keep local |
| `ticket-ephemeral` | Closed-ticket diary without durable invariant | Propose retire or distill-then-promote |
| `already-documented` | Covered by AGENTS/CONTRIBUTING/ADR/shared entry | Propose thin/delete local |
| `secret-blocked` | Secrets/credentials | Never promote raw; scrub or runbook |

## Promotion rules

1. Distill to one invariant / pattern / gotcha / lesson per file.
2. Run Step 3 overlap/safety gates.
3. Propose path: `.agent-tools/memory/entries/<slug>.md` + MEMORY.md line.
4. After user approval: write shared file, update index, **retire or thin** local copy to a pointer at the shared path (no dual full body).
5. Optional separate proposal lines for L2 drift (e.g. AGENTS contradicts a promoted process rule) — never silent AGENTS rewrite.

## Legacy `docs/solutions/` migration

When `--migrate-solutions` is set, **or** maintain detects legacy tree and user opts into migrate:

1. Inventory `docs/solutions/**/*.md` (skip pure templates if empty of content).
2. Map `docs/solutions/<cat>/<slug>.md` → `.agent-tools/memory/solutions/<cat>/<slug>.md` (normalize category to known set or `misc/`).
3. Propose **move** (default): write new location, remove old files (prefer `git mv` when applying).
4. Light link sweep: grep repo for `docs/solutions/` references; propose updates (AGENTS, CONTRIBUTING, planning, solution cross-links).
5. Optional stub: only if user chooses — short `docs/solutions/README.md` pointing at the new home (default is full move, no stub).
6. Do **not** enumerate migrated solutions in MEMORY.md Entries.
7. On apply: set `state.yml` → `solutions_migrated_from_docs: true` and timestamp.
8. Soft-warn on future capture/maintain if legacy tree remains and not migrated.

Never silent-migrate on setup or first maintain without approval.

## Maintain Output

```markdown
## Memory Quality Report

**L1**: […]
**L2**: [AGENTS.md — N lines]
**L3-shared**: [E entries, S solutions, MEMORY.md Entries section N lines]
**L3-local**: [harness, N files, index N lines]
**Legacy docs/solutions/**: [absent | N files | migrated]

### Health Score
P1 / P2 / P3 counts

### Findings
#### P1 — Critical
#### P2 — Important
#### P3 — Suggestions

### Proposed Refinements

#### L1 — Global
| # | Action | Target | Description | Priority |

#### L2 — Project Guide
| # | Action | Target | Description | Priority |

#### L3-shared
| # | Action | Target | Description | Priority |

#### L3-local
| # | Action | Target | Description | Priority |

#### Promote → shared
| # | Source (local) | → entries/<slug> | Distill summary | Gates |

#### Migrate solutions (if applicable)
| # | From | To | Notes |

#### Retire / thin local after promote
| # | Target | Action |

**Net Effect**: N creates, N updates, N deletes, N promotes, N migrates
```

## Applying Refinements

After review:
1. **Full approval** — "approve all"
2. **Selective** — "approve G1, M2, P1-P3"
3. **Revision** — "change M2 to…"
4. **Rejection** — "skip"

Execute creates before updates; promotes before local retires; deletes after merges. **User approval required before any write/delete.**

Then update `.agent-tools/memory/state.yml`:

```yaml
schema_version: 1
interval_days: 7
last_maintain_at: <ISO-8601>
snooze_until: null
last_maintain_result:
  p1: 0
  p2: 0
  p3: 0
  promoted: 0
  retired: 0
  migrated_solutions: 0
solutions_migrated_from_docs: false  # true after successful migrate
```

Show summary and new MEMORY.md Entries line count.
