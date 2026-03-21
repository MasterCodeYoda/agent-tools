---
name: evolve
description: Detect gaps in shared skills and commands, propose targeted improvements, validate changes, and present for review
argument-hint: "[scope: path, category, or 'all'] [--dry-run] [--limit N] [--iterate N] [--compound]"
---

# Evolve: Iterative Skill & Command Improvement

Apply the autoresearch pattern — detect → propose → validate → present — to iteratively improve the shared skills and commands in this repository.

**Core principle:** Every proposed change must trace to a concrete, detected gap. No vibes-based rewrites. No style preferences. If there's no gap, there's no change.

## User Input

```text
$ARGUMENTS
```

## Input Detection

Parse input to determine scope and mode:

| Input Pattern | Scope | Action |
|---|---|---|
| `all` or empty | Full inventory | Scan all `skills/` and `commands/` |
| `skills/<name>` | Single skill | Focus on one skill + its referencing commands |
| `commands/<path>` | Single command | Focus on one command + its referenced skills |
| `--category structural` | Category filter | Only structural integrity gaps |
| `--category coverage` | Category filter | Only coverage alignment gaps |
| `--category consistency` | Category filter | Only consistency gaps |
| `--dry-run` | Mode modifier | Detect and report only — no proposals, no branch |
| `--limit N` | Proposal cap | Generate proposals for top N gaps per iteration (default: 5) |
| `--iterate N` | Loop mode | Run N detect→propose→validate iterations (default: 5). Each iteration applies its proposals, then re-detects on the modified state. Stops early if no P1/P2 gaps remain. |
| `--iterate 1` | Single-pass | Equivalent to the non-loop behavior — detect, propose, done |
| `--compound` | Compound mode | Activate Phase 3 compound analysis (feedback signals, cross-domain synthesis, scenario health). Auto-activates when evolution history has 3+ entries. |

Flags combine: `skills/code-patterns --category coverage --limit 3 --iterate 3` is valid.

## Auto-Detection Phase

Before analysis, inventory the ecosystem:

```
1. Enumerate all skills: glob skills/*/SKILL.md
2. For each skill: catalog sub-files (references/, languages/, templates/, examples/)
3. Enumerate all shared commands: glob commands/**/*.md
4. For each command: extract @skill-name references and named agent definitions
5. Build initial reference graph: which commands reference which skills
6. Report inventory summary before proceeding
```

## Scope Gate

Based on inventory size:

- **Standard** (current repo size — ~8 skills, ~15 commands): Run all tiers automatically
- **If repo grows significantly** (30+ skills/commands): Run Tier 1 automatically, prompt before Tier 2/3

## Agent Reasoning Standards

All detection agents must follow these principles:

- **Cite evidence.** Every gap must reference specific file paths and, where applicable, line numbers or section headings. No gap without a concrete citation.
- **Check for intentional omission.** Before reporting a coverage gap, consider whether the omission is deliberate. Not every skill needs enforcement in every command. If a reasonable justification exists, note it and downgrade to P3 or skip.
- **Distinguish missing from misplaced.** A pattern might exist but live in a different file or section than expected. Verify it's truly absent, not just in an unexpected location.
- **No style opinions.** Do not flag tone, voice, formatting preferences, or prose quality. Only flag structural, coverage, and consistency issues with concrete evidence.

## Gap Detection

### Tier 1 — Structural Integrity (always runs)

Spawn 2 parallel agents that read all skill and command files:

**schema-validator** — Check structural compliance of all files:

For each `skills/*/SKILL.md`:
- YAML frontmatter must include `name` and `description`
- Must have a purpose/introduction section explaining the skill
- Must have a "When to Use This Skill" section (or clear equivalent)
- Should reference which commands consume this skill
- Should list related skills for boundary clarity
- Internal file references (e.g., `references/layer-patterns.md`, `languages/python.md`) must resolve to actual files within the skill's directory

For each `commands/**/*.md`:
- YAML frontmatter must include `name`, `description`, and `argument-hint`
- Must have a `User Input` section containing `$ARGUMENTS`
- Must define named agents with explicit skill references as criteria sources
- Must have an output format section
- Should have: Auto-Detection Phase, Scope Gate, Integration Points
- Agent definitions should cite specific skill files (not just `@skill-name` but which sub-files)

**cross-reference-auditor** — Check reference integrity:
- Find all `@skill-name` references in commands and skills
- Verify each resolves to a corresponding `skills/<name>/SKILL.md`
- Find all inter-file path references within skill files (e.g., `references/X.md`)
- Verify each path exists relative to the skill's root directory
- Identify **orphaned skills**: skills not `@referenced` by any command
- Identify **unanchored commands**: commands whose agents don't `@reference` any skill as criteria
- Identify **dead links**: internal file paths in any document that don't resolve
- Check that "Related Skills" and "Commands" sections accurately reflect actual references

### Tier 2 — Coverage Alignment (always runs)

Spawn 2 parallel agents:

**pattern-coverage-analyzer** — Build the skills-to-commands alignment matrix:

For each skill (read SKILL.md + key sub-files):
1. Extract the concrete patterns, checks, and concepts the skill defines
2. Note which are specific and enforceable vs. aspirational guidance

For each audit/review command (read the .md file):
1. Extract each named agent's check criteria (the bulleted lists under each agent)
2. Note which skill each agent cites as its reference

Build alignment and report:
- **Unbacked patterns** (P2): Specific, actionable patterns defined in a skill that no command agent checks for. These are guidance we teach but never enforce.
- **Ungrounded checks** (P2): Checks a command agent performs that aren't grounded in any referenced skill. The agent checks for something with no backing guidance.
- **Missing skill references** (P3): Commands that check for concepts from a skill they don't explicitly `@reference`. The check works but the criteria chain is undocumented.
- **Scope gaps** (P1): Entire substantial categories of skill guidance with no corresponding audit command coverage at all.

**language-parity-checker** — Check language coverage consistency:
- For skills with language-specific guides (`code-patterns`, `clean-architecture`):
  - List which languages have dedicated guides in each skill
  - Flag asymmetries between skills that cover the same language set
  - Within a single skill's language guides: flag if one language covers a topic that others skip (unless the topic is language-inappropriate)
- For commands that reference language-specific skill content:
  - Check that the command's agents mention the same language set as the skills they reference
- Severity: P3 for missing language coverage (often intentional), P2 for significant depth asymmetry within existing guides

### Tier 3 — Consistency Analysis (AI judgment)

Spawn 2 parallel agents:

**terminology-consistency-reviewer**:
- Read all SKILL.md files and their primary reference sub-files
- Identify concepts that appear across multiple skills
- Flag where the same concept uses different terminology across skills:
  - Architecture layer naming (consistent across clean-architecture, code-patterns, workflow-guide?)
  - Testing vocabulary (consistent between test-strategy and code-patterns testing sections?)
  - Pattern names (repository, gateway, adapter — used identically everywhere?)
- Flag contradictory guidance: skill A recommends X, skill B recommends the opposite
- Severity: P2 for contradictions that would cause agents to behave inconsistently, P3 for terminology drift

**scope-boundary-reviewer**:
- Identify guidance that overlaps between skills (e.g., testing guidance appears in both test-strategy and code-patterns)
- For each overlap: is one skill clearly authoritative? Does the other defer to it?
- Flag areas where a user or agent wouldn't know which skill to consult
- Check that "Related Skills" sections accurately describe boundaries and deference
- Check that command agent prompts don't blend guidance from multiple skills without clear attribution
- Severity: P3 for unclear boundaries (usually manageable), P2 if overlaps create contradictory agent behavior

## Gap Report

Present findings using the standard prioritized format:

```markdown
## Evolution Gap Report

**Scope**: [what was analyzed]
**Skills**: [N] skills, [M] sub-files
**Commands**: [N] commands
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

| Score Range | Label |
|-------------|-------|
| 90-100 | Excellent |
| 75-89 | Good |
| 60-74 | Fair |
| 40-59 | Needs Work |
| 0-39 | Critical |

**Score: [N]/100 — [Label]**

### Coverage Alignment Matrix

Columns represent audit domains within `/workflow:audit`. Individual `audit-*.md` files serve as domain definitions.

| Skill | Code | Tests | API | Frontend | Docs | Repo | QA | Review |
|-------|------|-------|-----|----------|------|------|----|--------|
| code-patterns | [status] | — | — | [status] | — | — | — | [status] |
| clean-architecture | [status] | — | [status] | [status] | — | — | — | [status] |
| test-strategy | — | [status] | — | — | — | — | — | [status] |
| visual-design | — | — | — | [status] | — | — | — | — |
| qa | — | — | — | — | — | — | [status] | — |
| workflow-guide | — | — | — | — | [status] | [status] | — | — |

Legend: Full = all major patterns covered | Partial = some gaps | — = no coverage expected | Missing = coverage expected but absent

### Findings

#### P1 — Critical Gaps
[Scope gaps, contradictions, structural failures]

#### P2 — Important Gaps
[Unbacked patterns, ungrounded checks, depth asymmetries, terminology conflicts]

#### P3 — Minor Gaps
[Missing @references, language parity, unclear boundaries, terminology drift]

### Positive Observations
[Well-structured areas, strong cross-referencing, consistent patterns]
```

**If `--dry-run` is set: stop here. Present the report and exit.**

## Proposal Generation

For the top N gaps (default 5, configurable via `--limit`), generate targeted fix proposals.

### Proposal Constraints (CRITICAL — do not deviate)

1. **One file per proposal.** Each proposal edits exactly one file.
2. **One gap per proposal.** Each proposal addresses exactly one detected gap.
3. **Minimal diff.** Add what's missing, fix what's broken. Do not rewrite surrounding content.
4. **Preserve voice and formatting.** Match the existing file's tone, structure, and conventions.
5. **No adjacent improvements.** Do not "clean up" nearby content, add comments, or improve formatting of unchanged sections.
6. **Evidence-linked.** Every proposal must cite: the gap ID, the evidence, and why this specific change closes it.
7. **Size guard.** Proposals requiring > 40 changed lines are flagged as "large" — explain why the scope is necessary. If scope cannot be justified, convert to a recommendation instead.

### Proposal Priority Order

Address gaps in this priority order:
1. P1 gaps (structural failures, scope gaps, contradictions)
2. P2 gaps with mechanical fixes (broken references, missing frontmatter, dead links)
3. P2 gaps requiring content (unbacked patterns, ungrounded checks)
4. P3 gaps (only if P1/P2 are exhausted and --limit allows)

### Proposals That Require Content Generation

For gaps that require writing new content (e.g., adding a check to a command's agent prompt, adding a pattern to a skill):
- Read the surrounding context thoroughly — match depth, specificity, and format of adjacent items
- Add the minimum content needed — one bullet point for a missing check, one short section for a missing pattern
- Err on the side of too terse rather than too verbose — it's easier to expand later than to trim

### Proposals That Exceed Scope

Convert to **recommendations** (not proposals) when:
- The gap requires creating an entirely new file (e.g., a missing language guide)
- The fix requires coordinated changes across 3+ files
- The gap requires making a judgment call between competing approaches
- The change would exceed the 40-line size guard without justification

Recommendations appear in the output but don't generate commits.

## Validation

After generating each proposal, validate before committing:

1. **Structural re-check**: Does the modified file still have all required frontmatter and sections?
2. **Cross-reference re-check**: Do all @references and internal paths still resolve? Did the change introduce any new broken references?
3. **Regression check**: Does the change create any new gaps? (e.g., adding a pattern to a skill creates a new "unbacked pattern" gap if no command checks for it — acceptable if documented)
4. **Size compliance**: Is the diff within the 40-line guard?
5. **Effectiveness check** (when applicable): If `tests/scenarios/` contains a scenario whose `metadata.yaml` matches the skill or command being modified, AND the proposal changes agent definitions or skill guidance (not purely structural fixes like frontmatter or dead links), run the effectiveness measurement described in the Phase 2 section. Apply the keep/revert decision: if detection rate decreases or false positives increase, discard the proposal and convert to a recommendation with the effectiveness data as evidence.

Mark each proposal:
- **Validated** — all checks pass (including effectiveness if run)
- **Validated with caveats** — passes but has noted trade-offs (e.g., creates a new minor gap, or effectiveness unchanged)
- **Validated + effectiveness gain** — all checks pass AND detection rate improved (strongest signal)
- **Failed** — change introduces structural issues or effectiveness regression; discard and convert to recommendation

## Execution

### Branch Setup

1. Create branch: `evolve/YYYY-MM-DD`

### Iteration Loop

Run for `--iterate N` iterations (default: 5). Each iteration is one full detect→propose→validate→apply cycle.

```
for iteration in 1..N:
  1. Run gap detection (Tiers 1-3) on CURRENT state of skills/ and commands/
     - First iteration: this is the initial detection
     - Subsequent iterations: re-detect after prior iteration's changes were applied
  2. If no P1 or P2 gaps remain: stop early, report convergence
  3. Generate proposals for top --limit gaps
  4. Validate each proposal (structural + cross-ref + effectiveness)
  5. Apply validated proposals: edit files, commit individually
  6. Log iteration summary
```

**Early termination conditions:**
- No P1 or P2 gaps detected → converged, stop
- No proposals validated successfully in an iteration → stuck, stop
- All remaining gaps are recommendations (exceed scope) → stop

### Commit Format

For each validated proposal, commit with:

```
evolve(<file-stem>): <concise change description>

Gap: <gap-type> — <description>
Evidence: <file:line or file:section citations>
Validation: <result>
Iteration: <N> of <total>
```

### Iteration Reporting

After each iteration, briefly report:
```
Iteration N: [M] gaps detected, [K] proposals applied, score [before] → [after]
```

After all iterations complete (or early termination), present the full evolution report.

## Output

```markdown
## Evolution Complete

**Iterations**: [N] of [max] ([converged | stopped: no validated proposals | stopped: limit reached])
**Gaps Detected**: [N] total across all iterations (P1: [n], P2: [n], P3: [n])
**Proposals Applied**: [N] total ([N] validated, [N] with caveats, [N] failed)
**Effectiveness Checks**: [N] run, [N] improved, [N] neutral, [N] reverted
**Recommendations**: [N] (gaps too large for automated proposal)
**Branch**: `evolve/YYYY-MM-DD` ([N] commits)

### Iteration Summary

| Iteration | Gaps Found | Proposals Applied | Score |
|-----------|-----------|-------------------|-------|
| 1 | [n] (P1:[n] P2:[n] P3:[n]) | [n] | [before] → [after] |
| 2 | [n] | [n] | [before] → [after] |
| ... | ... | ... | ... |
| **Final** | | | **[score]/100 — [Label]** |

### Proposals Applied

#### 1. `<target file>` — <change summary>
**Gap**: P[N] — <gap type>: <description>
**Change**: <what was added/modified>
**Evidence**: <citations>
**Validation**: <result>
**Iteration**: [N]

<diff>

#### 2. ...

### Effectiveness Results (if scenarios were run)

| Scenario | Planted | Baseline | Final | Delta |
|----------|---------|----------|-------|-------|
| [name] | [n] | [n/n] (N%) | [n/n] (N%) | [+/-N%] |

### Recommendations (manual action needed)

- [ ] <recommendation with rationale>
- [ ] ...

### Remaining Gaps
[P1/P2 gaps not addressed — either exceed scope or iterations exhausted]

### Score Impact
**Initial**: [N]/100 — [Label]
**Final**: [N]/100 — [Label]
**Delta**: [+/-N] points across [N] iterations

### Next Steps
1. Review branch `evolve/YYYY-MM-DD` — examine each commit
2. Merge, cherry-pick, or discard individual proposals
3. Re-run `/evolve` to continue improvement (if remaining gaps exist)
```

## Evolution Tracking

After each run, append to `.claude/evolve/history.md` (create if needed):

```markdown
## YYYY-MM-DD

- **Score**: [initial] → [final]/100 ([Label])
- **Iterations**: [N] of [max] ([termination reason])
- **Gaps**: [N] detected, [N] addressed
- **Proposals**: [N] applied ([N] validated, [N] with caveats)
- **Effectiveness**: [N] checks run, [N] improved ([detection rate delta])
- **Branch**: evolve/YYYY-MM-DD
- **Status**: pending review
- **Key changes**: [brief list of most impactful proposals]
```

On subsequent runs, show the score trend if history exists.

When the user merges or discards the branch, update the status entry on next run.

## Integration Points

### With /workflow:audit-*

Audit commands consume skills as criteria. Evolve ensures the skill-to-command pipeline is complete and consistent. When audits consistently miss known issues, the coverage alignment matrix reveals which skill gap explains it.

### With /workflow:review

Use `/workflow:review` on the evolve branch before merging — apply the same rigor as any code change to the agent tooling itself.

### With /workflow:compound

If an evolution run reveals a systemic pattern worth documenting (e.g., "we consistently under-specify agent checks for boundary patterns"), capture it via compound.

### Self-referential changes

This command may detect gaps in its own definition or in the `.claude/` project-local files. This is expected and allowed. Self-referential proposals are flagged for extra review scrutiny in the output.

## Effectiveness Loop (Phase 2)

When synthetic test scenarios exist in `tests/scenarios/`, use them to validate that skill/command changes actually improve agent detection capability. This is the external metric — the equivalent of autoresearch's `val_bpb`.

### Scenario Structure

Each scenario in `tests/scenarios/<name>/` contains:

```
<scenario-name>/
  metadata.yaml      # Which skill + command + agents this tests
  expected.yaml      # Ground truth: what the audit SHOULD find
  code/              # Synthetic codebase with planted issues
```

**metadata.yaml** fields:
- `name`: Scenario identifier
- `skill`: Which skill's guidance is being tested
- `command`: Which audit command to run
- `agents_tested`: Which specific agents within the command
- `planted_issues`: Count of planted issues (for quick reference)

**expected.yaml** fields per finding:
- `id`: Unique identifier (e.g., DRV-01)
- `severity`: Expected P1/P2/P3
- `type`: Issue type (e.g., dependency-rule-violation, assertion-free-test)
- `file`: Which planted file contains the issue
- `description`: What the audit should detect
- `skill_pattern`: Which specific skill section defines this as an issue
- `agent`: Which command agent should catch it

### Effectiveness Measurement

When a proposal targets a skill or command that has associated scenarios:

**Step 1 — Baseline measurement:**
1. Identify scenarios where `metadata.yaml` matches the affected skill or command
2. Spawn an agent for each matching scenario that:
   - Reads the scenario's `code/` directory as if it were a real codebase
   - Applies the relevant audit command's agent prompts (from the CURRENT skill/command definitions)
   - Produces findings in the standard P1/P2/P3 format
3. Compare agent findings against `expected.yaml`
4. Calculate **detection rate**: `(correctly identified issues) / (total planted issues)`
5. Record false positives: findings not in expected.yaml (should be 0 or minimal)

**Step 2 — Post-change measurement:**
1. Apply the proposed skill/command change
2. Re-run the same agents against the same scenarios, now using the MODIFIED definitions
3. Recalculate detection rate

**Step 3 — Decision:**
- **Detection rate improved, false positives stable** → Strong keep. Change provably improves effectiveness.
- **Detection rate unchanged, no regressions** → Neutral keep. Change may improve clarity without measurable effect. Accept if structural/coverage gap is closed.
- **Detection rate decreased OR false positives increased** → Revert. Convert to recommendation with explanation of why the change degraded detection.

### Detection Rate Scoring

Report per-scenario and aggregate:

```markdown
### Effectiveness Validation

| Scenario | Planted | Baseline | After Change | Delta |
|----------|---------|----------|--------------|-------|
| dependency-rule-violations | 6 | 4/6 (67%) | 5/6 (83%) | +17% |
| weak-test-suite | 7 | 6/7 (86%) | 6/7 (86%) | — |
| **Aggregate** | **13** | **10/13 (77%)** | **11/13 (85%)** | **+8%** |

False positives: 0 baseline → 0 after change
```

### When to Run Effectiveness Checks

- **Always** when a proposal modifies a skill that has matching scenarios
- **Always** when a proposal modifies a command's agent definitions that have matching scenarios
- **Skip** when a proposal is purely structural (frontmatter fix, dead link repair) — these don't affect agent detection behavior

### Adding New Scenarios

When creating new evolve scenarios:

1. **One scenario per skill-command pairing.** Keep scenarios focused.
2. **Plant 5-10 issues per scenario.** Enough to be statistically meaningful, small enough to maintain.
3. **Include 1-2 "good" examples.** The audit should NOT flag these — tests for false positives.
4. **Ground every planted issue in a specific skill pattern.** The `skill_pattern` field in expected.yaml must cite the exact section that defines this as an issue. If you can't cite it, the skill has a gap (which is itself an evolve finding).
5. **Keep code realistic.** Planted violations should look like real code, not strawmen. The audit should have to work to find them.

### Current Scenarios

| Scenario | Skill | Domain/Command | Planted Issues |
|----------|-------|----------------|----------------|
| `dependency-rule-violations` | clean-architecture | audit (code) | 6 |
| `weak-test-suite` | test-strategy | audit (tests) | 7 |
| `code-pattern-violations` | code-patterns | audit (code) | 8 |
| `api-design-violations` | clean-architecture | audit (api) | 8 |
| `frontend-quality-violations` | code-patterns | audit (frontend) | 8 |
| `documentation-quality-violations` | workflow-guide | audit (docs) | 7 |
| `visual-design-violations` | visual-design | audit (frontend) | 8 |
| `qa-coverage-violations` | qa | audit (qa) | 7 |
| `product-positioning-violations` | product | product:audit | 8 |

## Compound Learning (Phase 3)

Beyond detecting internal gaps and validating against synthetic scenarios, evolve can learn from real-world usage signals to identify what's working and what's missing.

### Feedback Signals

When invoked with `--compound` or when evolution tracking history has 3+ entries, activate compound analysis:

**Signal 1 — Audit finding patterns:**
If `/workflow:audit-code`, `/workflow:audit-tests`, or other audits have been run recently in user projects (check git log for compound docs in `docs/solutions/`), look for:
- **Recurring finding types** that no skill explicitly addresses — these are skill gaps discovered in the wild
- **Finding types that audits miss but users manually flag** — evidence of insufficient skill guidance
- **False positives** that users override or ignore — evidence of over-specification in skills

**Signal 2 — Evolution history analysis:**
Read `.claude/evolve/history.md` and git log for `evolve/` branches:
- Which proposals were merged vs. discarded? Discarded proposals reveal areas where automated proposals misjudge
- Which gap categories recur across runs? Recurring gaps suggest structural issues, not one-off omissions
- Score trend: is the ecosystem improving, plateauing, or regressing?

**Signal 3 — Scenario coverage analysis:**
Compare the skills-to-commands alignment matrix against `tests/scenarios/`:
- Which skill-command pairings have NO scenario? These can't be effectiveness-tested
- Which scenarios haven't been updated since the skill/command they test was modified?
- Which scenarios have low detection rates that haven't improved? These may indicate skill guidance that agents can't operationalize

### Cross-Domain Synthesis

When a gap or improvement is found in one skill-command pairing, check whether the insight applies elsewhere:

- A pattern added to `code-patterns` for Python → does `clean-architecture`'s Python guide need the same concept?
- A check added to `audit-code` → does `audit-frontend` need an analogous check for the frontend equivalent?
- A terminology fix in one skill → does the old term appear in other skills?

Cross-domain proposals are flagged as such: `"Cross-domain: originated from [source gap], applied to [target]"`.

### Scenario Generation

When a proposal adds a new pattern to a skill or a new check to a command, and no matching scenario exists:

1. Identify the skill-command pairing
2. Check `tests/scenarios/` for an existing scenario for that pairing
3. If none exists, recommend creating one (but do not auto-generate — scenarios require careful design of realistic planted violations)
4. If one exists, recommend adding a planted issue for the new pattern to the existing scenario's `code/` and `expected.yaml`

Format recommendation as:
```markdown
### Recommended Scenario Update

**Scenario**: tests/scenarios/<name>/
**Action**: Add planted issue for new pattern
**Pattern**: <skill-pattern reference>
**Suggested violation**: <description of realistic code that violates the pattern>
**Expected finding**: <what the audit should report>
```

### Compound Output

When compound analysis is active, append to the evolution report:

```markdown
### Compound Intelligence

**History**: [N] previous runs, [trend direction]
**Real-world signals**: [N] audit findings analyzed, [N] compound docs found
**Cross-domain opportunities**: [N] identified

#### Insights
- [Insight from history analysis]
- [Insight from real-world audit patterns]
- [Cross-domain opportunity]

#### Scenario Health
| Scenario | Last Updated | Detection Rate | Needs Update? |
|----------|-------------|----------------|---------------|
| dependency-rule-violations | YYYY-MM-DD | N% | [yes/no] |
| weak-test-suite | YYYY-MM-DD | N% | [yes/no] |

#### Recommended Scenario Updates
- [ ] [specific scenario addition recommendation]
```
