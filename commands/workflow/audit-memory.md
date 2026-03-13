---
name: workflow:audit-memory
description: Audit agent memory quality across the full hierarchy — structural integrity, codebase accuracy, and content quality — then produce an actionable refinement proposal
argument-hint: "[all, --level global|project|memory, --focus staleness|accuracy|scope|gaps|density]"
---

# Memory Quality Audit

Evaluate agent memory quality across the full hierarchy (Level 1 global, Level 2 project guide, Level 3 project memory) and produce a **refinement proposal** the user can approve, revise, or reject item-by-item before changes are applied.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine audit scope:

| Input Pattern | Scope | Action |
|---|---|---|
| `all` or empty | Full hierarchy (L1, L2, L3) | Audit all levels |
| `--level global` | Level 1 only | Audit `~/.claude/CLAUDE.md` |
| `--level project` | Level 2 only | Audit `<repo>/CLAUDE.md` |
| `--level memory` | Level 3 only | Audit project memory directory and `MEMORY.md` |
| `--focus staleness` | Cross-cutting | Staleness check across all levels |
| `--focus accuracy` | Cross-cutting | Accuracy verification across all levels |
| `--focus scope` | Cross-cutting | Scope placement analysis across all levels |
| `--focus gaps` | Cross-cutting | Gap analysis against codebase |
| `--focus density` | Cross-cutting | MEMORY.md optimization and density analysis |

## Auto-Detection Phase

Before analysis, detect the memory landscape:

```
1. Level 1 — Check ~/.claude/CLAUDE.md existence and size (line count, section count)
2. Level 2 — Check <repo>/CLAUDE.md existence and size (line count, section count)
3. Level 3 — Check project memory directory:
   a. MEMORY.md existence, line count, section structure
   b. Satellite files — count by type (user, feedback, project, reference)
   c. Frontmatter validity quick scan (parseable yes/no per file)
4. Project technology stack (for gap/completeness assessment)
5. Recent git history (last 30 days) — significant changes summary
6. Project structure (monorepo, multi-crate, single project, etc.)
7. Other projects sharing same global CLAUDE.md (cross-project scope signals)
8. Total memory surface area: combined line count across all levels
```

## Scope Gate

Based on auto-detection, determine audit depth:

- **Minimal** (< 5 memory files, MEMORY.md < 50 lines): All tiers run automatically
- **Standard** (5-15 files, MEMORY.md 50-150 lines): All tiers run automatically
- **Dense** (15+ files OR MEMORY.md > 150 lines): Tier 1 all; prompt user before Tier 2/3

## Agent Reasoning Standards

All audit agents must follow these reasoning principles, adapted for memory content:

- **Cite evidence on both sides.** Every finding must reference the memory `file:line` AND the codebase evidence that confirms or contradicts it. No finding without citations from both the memory and the live codebase.
- **Check the opposite hypothesis.** Before declaring a memory stale or inaccurate, search broadly — the concept may exist under a different name, in a different location, or behind an abstraction layer. A memory referencing something not found by grep may still be valid.
- **Verify before declaring stale.** Run at least two distinct searches (name-based and concept-based) before marking a memory as stale. Abstractions, renames, and indirection are common.
- **Respect intentional scope.** Some cross-project patterns intentionally live at Level 1. A memory appearing "misplaced" may reflect deliberate architectural decisions. Flag but don't auto-classify as P1.
- **Distinguish outdated from wrong.** A memory that was accurate when written but no longer applies (staleness) is different from a memory that was never accurate (error). Score and remediate differently.

## Three-Tier Analysis

### Tier 1 — Structural Integrity (always runs)

Spawn 3 parallel agents that examine memory structure:

**index-integrity-validator**:
- MEMORY.md exists and is non-empty
- Every `.md` file in the memory directory (excluding MEMORY.md) is referenced in MEMORY.md (detect orphans)
- Every path referenced in MEMORY.md actually exists on disk (detect broken references)
- MEMORY.md line count vs 200-line truncation limit (warning at 160+, critical at 190+)
- MEMORY.md has logical section organization (not a flat bullet dump)
- No duplicate references to the same file
- References use consistent formatting (relative paths, consistent link style)

**frontmatter-and-type-validator**:
- Every memory file (except MEMORY.md) has valid YAML frontmatter with `name`, `description`, `type` fields
- `type` value is one of: `user`, `feedback`, `project`, `reference`
- File naming convention aligns with declared type (e.g., `feedback_*.md` → `type: feedback`)
- `name` and `description` are meaningful (not empty, not trivially short like "stuff" or "note")
- No YAML frontmatter parsing errors (unclosed quotes, bad indentation, missing delimiters)
- `description` is specific enough to be useful for relevance filtering in future conversations

**scope-placement-analyzer**:
- Level 1 (`~/.claude/CLAUDE.md`) contains only user-wide preferences, not project-specific patterns or paths
- Level 2 (`<repo>/CLAUDE.md`) contains project guidance applicable to any contributor, not user-specific preferences
- Level 3 memory files contain project+user-specific knowledge, not universal wisdom that belongs at Level 1
- Check for information duplicated across levels (same guidance at L1 and L2, or L2 and L3)
- Check for scope misplacements in both directions:
  - Project-specific info at global level (paths, tools, patterns unique to one repo)
  - User-wide preferences buried in project memory (editor settings, communication style)
- Check for L2 content that should be L3 (user-specific decisions recorded as project conventions)

### Tier 2 — Codebase Cross-Reference (runs against live repository)

Spawn 3 parallel agents that verify memory claims against the current codebase:

**staleness-detector**:
- Memories referencing specific files, directories, or modules → verify they still exist at those paths
- Memories referencing tools, commands, or scripts → verify still present and functional
- Memories referencing configuration patterns → verify patterns still match actual config
- Memories describing removals or deprecations → verify the removed thing is actually gone
- Date-stamped entries → cross-reference against git history for reverts or supersession
- Technology/dependency claims → verify against current lock files and config (Cargo.toml, package.json, etc.)

**accuracy-verifier**:
- Claims of "we use X" or "the pattern is Y" → verify against actual codebase state
- File path references → verify paths are current and point to expected content
- Architecture and system descriptions → verify against current code structure and directory layout
- Dependency and tooling claims → verify against current config files
- Convention claims ("we always do X") → spot-check recent code for compliance
- Workflow descriptions → verify against current CI/CD config and scripts

**gap-detector**:
- Recent git history (60 days) for significant changes NOT reflected in any memory level
- CLAUDE.md conventions that lack corresponding memory entries for rationale or context
- Recurring code patterns (detected via grep sampling) with no memory guidance
- Project-specific vocabulary or naming conventions used in code but undocumented in memory
- New dependencies added recently with no memory context about why or how they're used
- Architectural decisions visible in code structure but not captured in memory or ADRs

### Tier 3 — Heuristic Analysis (AI judgment)

Spawn 3 parallel agents that apply qualitative assessment:

**contradiction-detector**:
- Cross-level contradictions (L1 says X, L2 or L3 says not-X)
- Intra-level contradictions (two L3 memories give conflicting guidance)
- Evolved entries where an old version contradicts a newer version but both still appear
- Feedback memories that duplicate or conflict with each other
- Implicit contradictions (memory A implies behavior incompatible with memory B)
- Temporal contradictions (memory says "we stopped doing X" but another memory still recommends X)

**quality-and-actionability-reviewer**:
- Does each memory tell agents WHAT to do and WHY?
- Flag vague memories ("be careful with X" without explaining how to be careful)
- Flag verbose memories (content compressible without information loss)
- Flag incident logs that lack lessons learned or actionable takeaways
- Flag feedback memories missing the **Why:** and **How to apply:** structure
- Flag project memories missing context about motivation or constraints
- MEMORY.md descriptions — are they specific enough for relevance filtering?
- Overall signal-to-noise ratio assessment

**consolidation-advisor**:
- Related memories that could merge into a single comprehensive entry
- Accretion memories (dates/revisions appended over time) that need a clean rewrite
- Feedback memories addressing the same root cause from different angles
- Long inline content in MEMORY.md that should extract to separate files (density reduction)
- Short separate files that could inline back into MEMORY.md (complexity reduction)
- Optimal MEMORY.md section structure recommendation
- Redundant entries across levels that could consolidate to one authoritative location

## Output: Prioritized Report

Present findings using the following structure:

```markdown
## Memory Audit Complete

**Scope**: [levels audited]
**Level 1**: [~/.claude/CLAUDE.md — N lines, present/absent]
**Level 2**: [<repo>/CLAUDE.md — N lines, present/absent]
**Level 3**: [N memory files, MEMORY.md at N/200 lines]
**Tiers Run**: [1, 2, 3] or [1 only]

### Health Summary

| Metric | Value | Status |
|--------|-------|--------|
| Index integrity (orphans / broken refs) | N orphans, N broken | [ok/warning/critical] |
| Frontmatter validity | N/N valid | [ok/warning/critical] |
| MEMORY.md density | N/200 lines (N%) | [ok/warning/critical] |
| Stale memories | N entries | [ok/warning/critical] |
| Inaccurate memories | N entries | [ok/warning/critical] |
| Contradictions | N found | [ok/warning/critical] |
| Scope misplacements | N entries | [ok/warning/critical] |
| Undocumented gaps | N detected | [ok/warning/critical] |
| Redundant / duplicate entries | N entries | [ok/warning/critical] |
| Low-actionability entries | N entries | [ok/warning/critical] |

### Health Score

Calculate from findings:
- Start at 100
- Each P1: -12 points
- Each P2: -4 points
- Each P3: -1 point
- Floor: 0

| Score Range | Label |
|-------------|-------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Fair |
| 40-59 | Needs Work |
| 0-39 | Critical |

**Score: [N]/100 — [Label]**

### Findings

#### P1 — Critical (Structural / Accuracy Failures)
[Broken index references, inaccurate memories that would mislead agents, severe scope misplacements, contradictions that cause conflicting behavior]

#### P2 — Important (Staleness / Quality Gaps)
[Stale memories referencing removed code, missing frontmatter fields, vague or unactionable entries, significant undocumented gaps, MEMORY.md approaching density limit]

#### P3 — Suggestions (Optimization)
[Consolidation opportunities, minor naming inconsistencies, density optimization, section reorganization, entries that could be more concise]

### Positive Observations
[Well-structured areas, accurate and actionable entries, good use of the type system, effective cross-level organization]

---

### Proposed Refinements

#### Level 1 — Global (`~/.claude/CLAUDE.md`)

| # | Action | Target | Description | Priority |
|---|--------|--------|-------------|----------|
| G1 | [add/update/remove/move] | [section or line range] | [what and why] | [P1/P2/P3] |
| G2 | ... | ... | ... | ... |

#### Level 2 — Project Guide (`<repo>/CLAUDE.md`)

| # | Action | Target | Description | Priority |
|---|--------|--------|-------------|----------|
| P1 | [add/update/remove/move] | [section or line range] | [what and why] | [P1/P2/P3] |
| P2 | ... | ... | ... | ... |

#### Level 3 — Project Memory

**MEMORY.md changes:**

| # | Action | Target | Description | Priority |
|---|--------|--------|-------------|----------|
| M1 | [add/update/remove/reorganize] | [line range or section] | [what and why] | [P1/P2/P3] |
| M2 | ... | ... | ... | ... |

**Memory file changes:**

| # | Action | Target File | Description | Priority |
|---|--------|-------------|-------------|----------|
| F1 | [create/update/delete/merge] | [filename] | [what and why] | [P1/P2/P3] |
| F2 | ... | ... | ... | ... |

**Net Effect**: N creates, N updates, N deletes, N merges — MEMORY.md goes from N to ~N lines
```

## Applying Refinements

After the user reviews the proposal:

1. **Full approval** — "approve all" or "apply all": Execute all proposed changes
2. **Selective approval** — "approve G1, M2, F1-F3": Execute only the specified items
3. **Revision** — "change M2 to instead...": Modify the proposal and re-present
4. **Rejection** — "skip" or "reject all": No changes applied

When applying approved changes:
- Execute in dependency order (creates before updates that reference them, deletes after merges)
- After applying, show a summary of what changed and the new MEMORY.md line count
- Offer to re-run audit to verify improvements

## Actionable Next Steps

After presenting the report, offer:

```markdown
## Next Steps

1. **Review proposed refinements** — Approve, revise, or reject items by their # identifiers (e.g., "approve G1, M2, F1-F3")
2. **Apply approved changes** — Execute the refinement plan
3. **Re-audit after changes** — Run `/workflow:audit-memory` to verify improvements
4. **Run complementary audits** — `/workflow:audit-repo` for infrastructure, `/workflow:audit-docs` for documentation
5. **Save report** — Export findings to `./planning/memory-audit-report.md`
```

## Integration Points

### With /workflow:audit-repo

audit-repo detects CLAUDE.md infrastructure (existence, structure, quality of agent documentation). audit-memory validates the *content* within that infrastructure — accuracy, staleness, scope placement, and actionability.

### With /workflow:audit-docs

audit-docs evaluates documentation quality broadly. audit-memory cross-validates documentation paths referenced in memory entries and checks that memory-documented conventions match what's in the docs.

### With /workflow:execute

During execution, if a memory audit was recently run, reference its findings to avoid acting on stale or inaccurate memory entries. Particularly important for memories flagged as stale or contradictory.

### With /workflow:review

When code changes affect patterns documented in memory, flag memory entries that may need updates. Review should reference memory audit findings for areas where memory is known to be stale.

### With /workflow:compound

If audit reveals areas where memory consistently goes stale (e.g., a fast-changing module), document a process for keeping that memory current. Compound can capture the pattern of "when X changes, update memory Y."

## Verification

After implementation, validate by:
1. Running the command against a project with rich memory (e.g., the inklings project at `~/.claude/projects/-Users-matthew-overlund-Source-OMG-inklings/memory/`)
2. Confirming all 3 tiers produce meaningful output
3. Confirming the refinement proposal is individually actionable with `#` identifiers
4. Confirming MEMORY.md density tracking reports correctly against the 200-line limit
5. Confirming cross-level scope analysis catches intentional vs accidental misplacements

## References

- Agent memory system specification (system prompt `# auto memory` section) — canonical source for memory types, frontmatter format, and MEMORY.md conventions
- [react-doctor](https://github.com/millionco/react-doctor) — Health scoring concept adapted from this React diagnostic CLI
