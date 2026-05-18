---
name: skills:evolve
description: Detect gaps in the canonical skill corpus, propose targeted improvements, validate changes, and present for review. Operates against src/skills/ using the new agent knowledge references and embedded markup system.
user-invocable: true
---

# Skills: Evolve

Apply the autoresearch pattern — detect → propose → validate → present — to iteratively improve the canonical skills under `src/skills/`.

**Core principle:** Every proposed change must trace to a concrete, detected gap. No vibes-based rewrites. No style preferences. If there's no gap, there's no change.

This is the canonical version of the evolve capability, now operating as a sub-skill of the `skills` meta-skill.

## Auto-Detection Phase

Before analysis, inventory the ecosystem:

```
1. Enumerate all skills: glob src/skills/*/SKILL.md
2. For each skill: catalog sub-files (references/, languages/, templates/, examples/, etc.)
3. Build initial reference graph: which skills reference other skills
4. Report inventory summary before proceeding
```

## Scope Gate

Based on inventory size:
- **Standard** (current repo size): Run all tiers automatically
- **If repo grows significantly**: Run Tier 1 automatically, prompt before Tier 2/3

## Agent Reasoning Standards

All detection agents must follow these principles:

- **Cite evidence.** Every gap must reference specific file paths and, where applicable, line numbers or section headings.
- **Check for intentional omission.** Before reporting a coverage gap, consider whether the omission is deliberate.
- **Distinguish missing from misplaced.** Verify a pattern is truly absent, not just in an unexpected location.
- **No style opinions.** Only flag structural, coverage, and consistency issues with concrete evidence.

## Gap Detection

### Tier 1 — Structural Integrity (always runs)

Spawn 2 parallel agents that read all skill files:

**schema-validator** — Check structural compliance of all files:

For each `src/skills/*/SKILL.md`:
- YAML frontmatter must include `name` and `description`
- Must have a purpose/introduction section explaining the skill
- Must have a "When to Use This Skill" section (or clear equivalent)
- Should reference related skills for boundary clarity
- Internal file references must resolve to actual files within the skill's directory

**cross-reference-auditor** — Check reference integrity:
- Find all `@skill-name` references in skills
- Verify each resolves to a corresponding `src/skills/<name>/SKILL.md`
- Find all inter-file path references within skill files
- Verify each path exists relative to the skill's root directory
- Identify **orphaned skills**: skills not referenced by any other skill
- Identify **dead links**: internal file paths that don't resolve

### Tier 2 — Coverage Alignment (always runs)

Spawn 2 parallel agents:

**pattern-coverage-analyzer** — Build the skills coverage matrix:

For each skill (read SKILL.md + key sub-files):
1. Extract the concrete patterns, checks, and concepts the skill defines
2. Note which are specific and enforceable vs. aspirational guidance

For each skill that contains agent definitions or audit/review logic:
1. Extract each named agent's check criteria
2. Note which skill each agent cites as its reference

Build alignment and report:
- **Unbacked patterns** (P2): Specific, actionable patterns defined in a skill that no agent checks for.
- **Ungrounded checks** (P2): Checks an agent performs that aren't grounded in any referenced skill.
- **Missing skill references** (P3)
- **Scope gaps** (P1): Entire substantial categories of skill guidance with no corresponding coverage.

**language-parity-checker** — Check language coverage consistency:
- For skills with language-specific guides:
  - List which languages have dedicated guides
  - Flag asymmetries between skills that cover the same language set
- Severity: P3 for missing coverage (often intentional), P2 for significant depth asymmetry.

### Tier 3 — Consistency Analysis (AI judgment)

Spawn 2 parallel agents:

**terminology-consistency-reviewer**:
- Read all SKILL.md files and their primary reference sub-files
- Identify concepts that appear across multiple skills
- Flag where the same concept uses different terminology
- Flag contradictory guidance
- Severity: P2 for contradictions that would cause agents to behave inconsistently, P3 for terminology drift

**scope-boundary-reviewer**:
- Identify guidance that overlaps between skills
- For each overlap: is one skill clearly authoritative? Does the other defer to it?
- Flag areas where a user or agent wouldn't know which skill to consult
- Severity: P3 for unclear boundaries, P2 if overlaps create contradictory agent behavior

## Gap Report

Present findings using the standard prioritized format:

```markdown
## Evolution Gap Report

**Scope**: [what was analyzed]
**Skills**: [N] skills, [M] sub-files
**Cross-references**: [N] @-references checked, [N] internal paths checked

### Ecosystem Health

| Dimension | Findings | Status |
|-----------|----------|--------|
| Structural integrity | [N] issues | [ok/warning/critical] |
| Cross-reference integrity | [N] issues | [ok/warning/critical] |
| Coverage alignment | [N] gaps | [ok/warning/critical] |
| Language parity | [N] asymmetries | [ok/warning/critical] |
| Terminology consistency | [N] conflicts | [ok/warning/critical] |
| Scope clarity | [N] overlaps | [ok/warning/critical] |

### Health Score

- Start at 100
- Each P1: -12 points
- Each P2: -4 points
- Each P3: -1 point
- Floor: 0

**Score: [N]/100 — [Label]**

### Findings

#### P1 — Critical Gaps
[Scope gaps, contradictions, structural failures]

#### P2 — Important Gaps
[Unbacked patterns, ungrounded checks, depth asymmetries, terminology conflicts]

#### P3 — Minor Gaps
[Missing references, language parity, unclear boundaries, terminology drift]

### Positive Observations
[Well-structured areas, strong cross-referencing, consistent patterns]
```

**If `--dry-run` is set: stop here. Present the report and exit.**

## Proposal Generation

For the top N gaps (default 5), generate targeted fix proposals.

### Proposal Constraints (CRITICAL — do not deviate)

1. **One file per proposal.** Each proposal edits exactly one file.
2. **One gap per proposal.** Each proposal addresses exactly one detected gap.
3. **Minimal diff.** Add what's missing, fix what's broken. Do not rewrite surrounding content.
4. **Preserve voice and formatting.** Match the existing file's tone, structure, and conventions.
5. **No adjacent improvements.** Do not "clean up" nearby content.
6. **Evidence-linked.** Every proposal must cite: the gap ID, the evidence, and why this specific change closes it.
7. **Size guard.** Proposals requiring > 40 changed lines are flagged as "large" — explain why the scope is necessary.

### Proposal Priority Order

1. P1 gaps (structural failures, scope gaps, contradictions)
2. P2 gaps with mechanical fixes
3. P2 gaps requiring content
4. P3 gaps (only if P1/P2 are exhausted)

### Proposals That Exceed Scope

Convert to **recommendations** (not proposals) when:
- The gap requires creating an entirely new file
- The fix requires coordinated changes across 3+ files
- The gap requires making a judgment call between competing approaches
- The change would exceed the 40-line size guard without justification

## Validation

After generating each proposal, validate before committing:

1. **Structural re-check**: Does the modified file still have all required frontmatter and sections?
2. **Cross-reference re-check**: Do all @references and internal paths still resolve?
3. **Regression check**: Does the change create any new gaps?
4. **Size compliance**: Is the diff within the 40-line guard?

Mark each proposal:
- **Validated**
- **Validated with caveats**
- **Validated + effectiveness gain**
- **Failed** (discard and convert to recommendation)

## Execution

### Branch Setup

1. Create branch: `evolve/YYYY-MM-DD`

### Iteration Loop

Run for `--iterate N` iterations (default: 5). Each iteration is one full detect→propose→validate→apply cycle.

```
for iteration in 1..N:
  1. Run gap detection on CURRENT state of src/skills/
  2. If no P1 or P2 gaps remain: stop early, report convergence
  3. Generate proposals for top --limit gaps
  4. Validate each proposal
  5. Apply validated proposals: edit files, commit individually
```

After all iterations (or early convergence), present a final summary of changes made, health score improvement, and any remaining gaps.

## Integration Points

- Uses agent capability quick-references from `src/skills/references/agents/`
- Uses the embedded markup system defined in `src/skills/references/MARKUP.md` when proposing portable changes
- Operates under the `skills` meta-skill (`src/skills/SKILL.md`)

---

*This is the canonical evolve capability. Once validated, the legacy implementation at `.claude/commands/evolve.md` and `.claude/evolve/` will be removed.*