---
name: workflow:compound
description: Capture durable knowledge from any engineering work — debugging solutions, refactors, features, design decisions, reusable patterns — and maintain memory quality so each unit of work compounds the next
argument-hint: "[context about what was solved] | --maintain [--level global|project|memory] [--focus staleness|accuracy|scope|gaps]"
user-invocable: true
---

# Knowledge Capture and Compounding

Compounding is about making **every unit of engineering work make subsequent work easier** — not just debugging. A solved bug, a refactor that revealed a cleaner structure, a feature that established a reusable pattern, a hard-won design decision: all of it is durable knowledge worth capturing. Debugging solutions are one important case, not the whole job. Whenever you finish non-trivial work and think "the next person (or the next me) would save real time knowing this," compound applies — regardless of whether anything was ever broken.

Two modes for managing your team's accumulated intelligence:

- **Capture mode** (default): Capture durable knowledge from recently completed work — a solved bug, a refactor, a new feature pattern, a design decision — and route it to the right home (a solution doc, project memory, an ADR, or AGENTS.md).
- **Maintain mode** (`--maintain`): Audit and refine agent memory quality across the full hierarchy

## Mode Detection

Parse `$ARGUMENTS` to determine mode:

| Input Pattern | Mode | Action |
|---|---|---|
| `--maintain` | Maintain | Run memory quality audit (see Maintain Mode below) |
| `--maintain --level global` | Maintain (scoped) | Audit `~/.claude/CLAUDE.md` only |
| `--maintain --level project` | Maintain (scoped) | Audit `<repo>/CLAUDE.md` only |
| `--maintain --level memory` | Maintain (scoped) | Audit project memory directory only |
| `--maintain --focus staleness` | Maintain (focused) | Staleness check across all levels |
| `--maintain --focus accuracy` | Maintain (focused) | Accuracy verification across all levels |
| `--maintain --focus scope` | Maintain (focused) | Scope placement analysis |
| `--maintain --focus gaps` | Maintain (focused) | Gap analysis against codebase |
| Any other input or empty | Capture | Capture durable knowledge from recent work (default behavior) |

---

# Capture Mode

## Purpose

**Why "compound"?** Each captured insight compounds your team's knowledge:
- First time working it out: Research / design / debugging (30+ minutes)
- After capturing: Quick lookup or reuse (2-3 minutes)
- Knowledge compounds over time

Each unit of engineering work should make subsequent units of work easier, not harder. That applies to a refactor that clarified a structure or a design decision settled after weighing trade-offs just as much as to a bug that got root-caused.

## What You're Capturing — and Where It Lives

Compound covers durable knowledge from **any** engineering work, not only debugging. Different shapes of knowledge have different natural homes. Classify the knowledge first, then capture it to the right place. The failure mode to avoid is capturing **nothing** because "this wasn't a bug, so compound doesn't apply" — that is exactly the perception this section exists to correct.

| Knowledge shape | Examples | Durable home |
|---|---|---|
| Debugging solution | Root-caused bug; build / test / runtime failure; performance or security fix | `docs/solutions/<category>/<slug>.md` (template below) |
| Reusable pattern or technique | A refactor that revealed a cleaner structure; an idiom now applied project-wide; a feature that established a repeatable approach | Project memory (Level 3) and/or AGENTS.md |
| Architecture / design decision | A trade-off chosen and why; a convention now in force; an approach rejected and the reason | Decision record (`docs/decisions/`) and/or project memory |
| Cross-cutting gotcha or constraint | "Module X must initialize before Y"; an environment quirk; a non-obvious invariant | Project memory; AGENTS.md if every contributor needs it |

Notes on routing:

- **A single piece of work can produce more than one artifact.** A refactor+feature can both establish a reusable pattern (→ memory) *and* fix a latent bug found along the way (→ solution doc). Capture each to its home rather than forcing everything into one shape.
- **When the home is memory, write the memory file directly** using the project's memory conventions (frontmatter with `name` / `description` / `type`, plus a one-line pointer in `MEMORY.md`) — do **not** bend a refactor or design decision into a debugging-shaped `docs/solutions/` post-mortem with empty "Symptoms" and "Root Cause" sections. The `Problem → Investigation → Root Cause → Solution` template below is the right shape **only** for debugging solutions.
- **Capture and maintenance are two halves of one lifecycle.** `--maintain` audits exactly the memory surface that pattern/decision/gotcha captures write to. If you're unsure whether memory already covers something, that's a signal to run `--maintain --focus gaps` afterward.
- **Maintain decision records in place.** When a captured decision changes one already recorded, **rewrite the existing record** to current state — do not append a supersession note, a tombstone, or a "previously we said X" block, and do not leave the old decision standing beside the new one. Keep the rationale and rejected alternatives; drop the change history. If the *reason it changed* is itself a durable, reusable lesson, that routes to memory — not back into the record as a changelog. See @workflow (`references/decision-records.md`). (Skip when the project elected `classic-immutable` in `planning/conventions.md`.)

The rest of Capture mode below details the **debugging-solution** path (categories, analysis agents, the solution-doc template) because that path has the most structure. For the memory / ADR / AGENTS.md paths, the routing table above plus the project's memory conventions are the procedure — capture the insight, its rationale, and when it applies, then link it from the relevant index.

## User Input

```text
$ARGUMENTS
```

## Invocation Modes

### 1. Session Boundary (Auto from Execute)
Pre-filled with session context:
```bash
/workflow:compound "Fixed N+1 query in brief generation"
```

### 2. On-Demand
Analyzes recent conversation and commits:
```bash
/workflow:compound
```

### 3. With Context Hint
User provides brief description:
```bash
/workflow:compound "resolved circular dependency in auth module"
```

## Undocumented Solution Surfacing

Before starting capture, check conversation history for completed work in this project — solved bugs, but also landed refactors, features, and settled decisions — that was never captured. References: @workflow (`references/conversation-analysis.md`)

```
1. Get project root: git rev-parse --show-toplevel
2. Read ~/.claude/history.jsonl — filter entries where "project" starts with project root (prefix match, not exact — handles subfolder sessions)
3. Group by sessionId to get distinct sessions for this project
4. For each session, read ~/.claude/usage-data/facets/{sessionId}.json (if exists)
5. Filter for sessions with outcome "fully_achieved" and a meaningful brief_summary
6. Cross-reference against docs/solutions/ — exclude sessions whose summary matches an existing compound doc
7. Present undocumented solutions (if any) before proceeding to capture
```

If undocumented solutions are found:
```markdown
Before we capture your current work, I found [N] prior sessions
that completed meaningful work in this project but never captured it:

1. [date] — [brief_summary from facet]
2. [date] — [brief_summary from facet]
3. [date] — [brief_summary from facet]

Would you like to document any of these as well?
- Select by number (e.g., "1, 3")
- "skip" to proceed with current capture only
- "all" to document everything

For selected items, I'll load the conversation context and run the
standard compound analysis.
```

If no undocumented solutions found, proceed directly to capture.

## Preconditions

Before documenting, verify:

- [ ] **Work is settled** - The bug is fixed, the refactor is landed, or the decision is made — not in-progress
- [ ] **It holds up** - The solution is confirmed working, or the pattern/decision is one you'd actually stand behind reusing
- [ ] **Non-trivial** - Worth documenting (not typos, obvious fixes, or restating what the code already makes plain)

If conditions not met, ask: "Is this work settled and worth capturing for next time?"

## Parallel Analysis

This multi-agent analysis is tuned for the **debugging-solution** path — its agents extract symptoms, root cause, and recurrence prevention. For a pattern, decision, or gotcha headed to memory / ADR / AGENTS.md, you don't need this fan-out: capture the insight, the alternatives weighed, and when it applies, then link it from the relevant index. Use the agents below when the artifact is a `docs/solutions/` entry.

Launch specialized agents simultaneously for efficient analysis:

### Agent 1: Context Analyzer
Extracts from conversation history:
- Problem type and category
- Component/module affected
- Observable symptoms
- Error messages if any

**Returns**: YAML frontmatter structure

### Agent 2: Solution Extractor
Analyzes investigation and fix:
- Steps tried (what didn't work)
- Root cause identified
- Working solution with code
- Key insights

**Returns**: Solution content block

### Agent 3: Related Docs Finder
Searches existing knowledge:
- Related docs in `docs/solutions/`
- Similar patterns elsewhere
- Cross-references to link
- GitHub issues if applicable

**Returns**: Links and relationships

### Agent 4: Prevention Strategist
Develops preventive measures:
- How to avoid recurrence
- Best practices to follow
- Test cases if applicable
- Warning signs to watch for

**Returns**: Prevention content

### Agent 5: Category Classifier
Determines organization:
- Best-fit category
- Filename from slug
- Tags for searchability
- Related categories

**Returns**: File path and metadata

## Debugging-Solution Categories (for `docs/solutions/`)

These categories apply when the artifact is a debugging-solution doc. Auto-classify into the appropriate one. (Pattern / decision / gotcha captures route to memory, ADR, or AGENTS.md instead — see *What You're Capturing* above.)

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

## Output Document (debugging-solution path)

For a debugging solution, create `docs/solutions/<category>/<slug>.md`. (Pattern / decision / gotcha captures use the project's memory / ADR / AGENTS.md conventions instead — capture the insight, its rationale, and when it applies, then link it from the relevant index.)

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

Link new docs to related content:
- Add cross-references in related documents
- Update index if exists
- Tag for discoverability

### With AGENTS.md (Optional)

For project-specific learnings:
```markdown
Consider adding to AGENTS.md:
- Pattern: [what we learned]
- When: [when it applies]
```

## Success Output

```markdown
## Knowledge Documented

**File created:**
`docs/solutions/[category]/[slug].md`

**Summary:**
- Problem: [one-line description]
- Category: [category]
- Tags: [tag list]

**Linked to:**
- [Related doc 1]
- [Related doc 2]

**Next time this happens:**
Search for: "[symptoms]" or browse `docs/solutions/[category]/`

---

What's next?
1. Continue workflow
2. View documentation
3. Add to related docs
4. Other
```

## The Compounding Philosophy

```
Build -> Test -> Find Issue -> Research -> Improve -> Document -> Deploy
  ^                                                                  |
  └──────────────────────────────────────────────────────────────────┘
         Each cycle builds on documented knowledge
```

### Value Accumulation

| Occurrence | Without Compound | With Compound |
|------------|------------------|---------------|
| First time | 30+ min research | 30+ min (document) |
| Second time | 20+ min research | 3 min lookup |
| Third time | 15+ min research | 2 min lookup |
| Team member | 30+ min research | 3 min lookup |

### When to Compound

**Always capture:**
- Non-obvious solutions (debugging)
- Environment-specific issues, integration problems, performance optimizations, security fixes
- Reusable patterns or techniques a refactor or feature established
- Non-obvious design decisions and the rationale / alternatives behind them
- Cross-cutting gotchas, invariants, or constraints future work must respect

**Skip capturing:**
- Typos and obvious fixes
- One-off issues unlikely to recur
- Knowledge already well-documented or that the code makes plain on its own
- Trivial configuration changes

## Quality Checklist

Before completing documentation:

- [ ] Problem clearly described
- [ ] Symptoms are searchable
- [ ] Root cause explained
- [ ] Solution is reproducible
- [ ] Prevention strategies included
- [ ] Tags enable discovery
- [ ] Related docs linked
- [ ] Code examples are accurate

## Commands to Remember

```bash
# After completing non-trivial work (a fix, refactor, feature, or decision)
/workflow:compound "brief context"

# Audit and maintain memory quality
/workflow:compound --maintain

# Search existing solutions
grep -r "symptom" docs/solutions/

# Browse by category
ls docs/solutions/[category]/
```

---

# Maintain Mode

Activated by `--maintain`. Evaluate agent memory quality across the full hierarchy (Level 1 global, Level 2 project guide, Level 3 project memory) and produce a refinement proposal the user can approve, revise, or reject item-by-item.

**Why maintenance belongs in compound:** You can't compound effectively on a foundation of stale or inaccurate memory. Capture and maintenance are two sides of the same knowledge lifecycle.

**Primitives reference:** For the underlying memory file types, settings, hooks, and slash commands this mode operates on — including the 200-line / 25 KB hard cutoff for `MEMORY.md`, `CLAUDE.md` scope precedence, `.claude/rules/` with `paths:` frontmatter, and how this mode relates to Anthropic's `/dream` — see @workflow (`references/memory-primitives.md`).

## Maintain Auto-Detection

```
1. Level 1 — Check ~/.claude/CLAUDE.md existence and size
2. Level 2 — Check <repo>/CLAUDE.md existence and size
3. Level 3 — Check project memory directory:
   a. MEMORY.md existence, line count
   b. Satellite files — count by type (user, feedback, project, reference)
   c. Frontmatter validity quick scan
4. Project technology stack (for gap assessment)
5. Recent git history (last 30 days)
6. Total memory surface area: combined line count across all levels
```

## Maintain Scope Gate

- **Minimal** (< 5 memory files, MEMORY.md < 50 lines): All tiers automatically
- **Standard** (5-15 files, MEMORY.md 50-150 lines): All tiers automatically
- **Dense** (15+ files OR MEMORY.md > 150 lines): Tier 1 all; prompt before Tier 2/3

## Maintain Agent Reasoning Standards

- **Cite evidence on both sides.** Every finding must reference the memory `file:line` AND the codebase evidence that confirms or contradicts it.
- **Check the opposite hypothesis.** Before declaring a memory stale, search broadly — the concept may exist under a different name or behind an abstraction.
- **Verify before declaring stale.** Run at least two distinct searches (name-based and concept-based) before marking stale.
- **Respect intentional scope.** Some cross-project patterns intentionally live at Level 1. Flag but don't auto-classify as P1.
- **Distinguish outdated from wrong.** Staleness (was accurate, no longer applies) differs from error (was never accurate). Score differently.

## Maintain Three-Tier Analysis

### Tier 1 — Structural Integrity

Spawn 3 parallel agents:

**index-integrity-validator**:
- MEMORY.md exists and is non-empty
- Every `.md` file in memory directory is referenced in MEMORY.md (orphans)
- Every path referenced in MEMORY.md exists on disk (broken references)
- MEMORY.md line count vs 200-line truncation limit (warning at 160+, critical at 190+)
- No duplicate references to the same file

**frontmatter-and-type-validator**:
- Every memory file has valid YAML frontmatter with `name`, `description`, `type`
- `type` is one of: `user`, `feedback`, `project`, `reference`
- `name` and `description` are meaningful (not empty or trivially short)
- No YAML parsing errors

**scope-placement-analyzer**:
- Level 1 contains only user-wide preferences, not project-specific patterns
- Level 2 contains project guidance for any contributor, not user preferences
- Level 3 contains project+user-specific knowledge, not universal wisdom
- Check for information duplicated across levels
- Check for scope misplacements in both directions

### Tier 2 — Codebase Cross-Reference

Spawn 3 parallel agents:

**staleness-detector**:
- Memories referencing specific files, directories → verify they exist
- Memories referencing tools, commands → verify still present
- Technology/dependency claims → verify against current lock files
- Date-stamped entries → cross-reference against git history

**accuracy-verifier**:
- Claims of "we use X" → verify against codebase
- File path references → verify paths are current
- Architecture descriptions → verify against code structure
- Convention claims → spot-check recent code for compliance

**gap-detector**:
- Recent git history (60 days) for significant changes NOT in memory
- CLAUDE.md conventions lacking rationale in memory
- Recurring code patterns with no memory guidance
- New dependencies with no memory context

### Tier 3 — Heuristic Analysis

Spawn 3 parallel agents:

**contradiction-detector**:
- Cross-level contradictions (L1 vs L2/L3)
- Intra-level contradictions (two L3 memories conflict)
- Temporal contradictions ("we stopped X" but another memory recommends X)

**quality-and-actionability-reviewer**:
- Does each memory tell agents WHAT and WHY?
- Flag vague memories ("be careful with X" without explaining how)
- Flag verbose memories compressible without information loss
- Flag feedback memories missing **Why:** and **How to apply:** structure
- Signal-to-noise ratio assessment

**consolidation-advisor**:
- Related memories that could merge
- Accretion memories needing clean rewrite
- Long inline MEMORY.md content that should extract to files
- Short files that could inline back into MEMORY.md

## Maintain Output

```markdown
## Memory Quality Report

**Level 1**: [~/.claude/CLAUDE.md — N lines]
**Level 2**: [<repo>/CLAUDE.md — N lines]
**Level 3**: [N memory files, MEMORY.md at N/200 lines]

### Health Score

[Same P1/P2/P3 scoring as capture mode reports]

### Findings

#### P1 — Critical (Structural / Accuracy Failures)
[Broken references, inaccurate memories, contradictions]

#### P2 — Important (Staleness / Quality Gaps)
[Stale memories, missing frontmatter, undocumented gaps]

#### P3 — Suggestions (Optimization)
[Consolidation, density optimization, section reorganization]

### Proposed Refinements

#### Level 1 — Global
| # | Action | Target | Description | Priority |
|---|--------|--------|-------------|----------|

#### Level 2 — Project Guide
| # | Action | Target | Description | Priority |
|---|--------|--------|-------------|----------|

#### Level 3 — Project Memory
| # | Action | Target File | Description | Priority |
|---|--------|-------------|-------------|----------|

**Net Effect**: N creates, N updates, N deletes, N merges
```

## Applying Refinements

After review:
1. **Full approval** — "approve all": Execute all proposed changes
2. **Selective approval** — "approve G1, M2, F1-F3": Execute specific items
3. **Revision** — "change M2 to instead...": Modify and re-present
4. **Rejection** — "skip": No changes applied

Execute in dependency order (creates before updates, deletes after merges). After applying, show summary and new MEMORY.md line count.
