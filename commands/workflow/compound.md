---
name: workflow:compound
description: Capture knowledge from solved problems and maintain memory quality to compound your team's effectiveness
argument-hint: "[context about what was solved] | --maintain [--level global|project|memory] [--focus staleness|accuracy|scope|gaps]"
---

# Knowledge Capture and Compounding

Two modes for managing your team's accumulated intelligence:

- **Capture mode** (default): Document recently solved problems to build a searchable knowledge base
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
| Any other input or empty | Capture | Document a solved problem (default behavior) |

---

# Capture Mode

## Purpose

**Why "compound"?** Each documented solution compounds your team's knowledge:
- First time solving a problem: Research (30+ minutes)
- After documenting: Quick lookup (2-3 minutes)
- Knowledge compounds over time

Each unit of engineering work should make subsequent units of work easier, not harder.

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

## Preconditions

Before documenting, verify:

- [ ] **Problem is solved** - Not in-progress
- [ ] **Solution is verified** - Confirmed working
- [ ] **Non-trivial** - Worth documenting (not typos or obvious fixes)

If conditions not met, ask: "Is this problem fully resolved and worth documenting?"

## Parallel Analysis

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

## Document Categories

Auto-classify into appropriate category:

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

## Output Document

Create `docs/solutions/<category>/<slug>.md`:

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

**Always document:**
- Non-obvious solutions
- Environment-specific issues
- Integration problems
- Performance optimizations
- Security fixes

**Skip documenting:**
- Typos and obvious fixes
- One-off issues
- Already well-documented problems
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
# After solving a problem
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
