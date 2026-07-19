# Compound maintain mode

Load when `$ARGUMENTS` includes `--maintain` (or after mode detection routes to maintain).

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

### L3-local → L3-shared

1. Distill to one invariant / pattern / gotcha / lesson per file.
2. Run Step 3 overlap/safety gates (compound capture).
3. Propose path: `.agent-tools/memory/entries/<slug>.md` + MEMORY.md line.
4. After user approval: write shared file, update index, **retire or thin** local copy to a pointer at the shared path (no dual full body).
5. Optional separate proposal lines for L2 drift (e.g. AGENTS contradicts a promoted process rule) — never silent AGENTS rewrite.

### L3-shared → durable docs (OpenWiki-lite)

Flag `entries/` that are stable product/architecture knowledge as **docs promote candidates**
(see compound Step 5). Default targets: `docs/`, `docs/design/`, `docs/research/` — never new
`docs/solutions/`. User approval required. After promote: set `promoted_to` on the entry; keep a
thin pointer in MEMORY.md. Process thrash entries (`type: process` for skill gaps) stay in L3
and feed `/skills:evolve` — do not promote those to product docs.

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
