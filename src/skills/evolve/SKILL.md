---
name: skills:evolve
description: Detect gaps in the canonical skill corpus, propose targeted improvements, validate, review, land on main, and remove the evolve branch. Inventories src/** skill trees; optional run-ledger seeds for process IP gaps. Abort is an explicit exception.
user-invocable: true
publish-target: project
---

# Skills: Evolve

Apply the autoresearch pattern — detect → propose → validate → **review → land** — to iteratively
improve the canonical skills under `src/` (all families: workflow, swarm, git, skills, …).

**Core principle:** Every proposed change must trace to a concrete, detected gap. No vibes-based
rewrites. No style preferences. If there's no gap, there's no change. **Process IP**
(workflow/swarm) changes only through this skill — never mid-loop from `/workflow:continue`.

**Completion is mandatory.** A run that stops at “present for review” or leaves
`evolve/YYYY-MM-DD` unmerged is **incomplete**. Default end state: changes reviewed, merged to
`main`, history recorded as `merged`, branch deleted. **Abort is the exception** — only when the
user explicitly opts out (reject proposals, discard the branch, or stop mid-land).

This is the canonical version of the evolve capability, now operating as a sub-skill of the
`skills` meta-skill.

## Auto-Detection Phase

Before analysis, inventory the ecosystem:

```
1. Enumerate all skills: find src -name SKILL.md  (every family, not only src/skills/)
2. For each skill root: catalog sub-files (references/, languages/, templates/, examples/, etc.)
3. Build initial reference graph: which skills reference other skills
4. Optional: load run-ledger seeds (below) and attach to detection context
5. Report inventory summary before proceeding
```

### Run-ledger seeds (optional Tier 0 input)

When the user provides process/yield focus, pastes seed YAML, or `.agent-tools/runs/` shows
thrash/rework clusters: **load** `references/run-ledger-seeds.md`. Convert confirmed seeds into
Gap Report findings with file evidence — still no proposal without a corpus mismatch.

## Scope Gate

Based on inventory size:
- **Standard** (current repo size): Run all tiers automatically
- **If repo grows significantly**: Run Tier 1 automatically, prompt before Tier 2/3
- **Process-seed run**: Always include `src/workflow/**` and `src/swarm/**` even if narrowing
  other families

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

For each discovered `SKILL.md` under `src/`:
- YAML frontmatter must include `name` and `description`
- Must have a purpose/introduction section explaining the skill
- Must have a "When to Use This Skill" section (or clear equivalent) when user-invocable
- Should reference related skills for boundary clarity
- Internal file references must resolve to actual files within the skill's directory

**Before proposing structure changes** (extractions, new templates/refs, merging content into
`SKILL.md`): **load** `@skills` (`references/thin-routing.md`). Treat as structural gaps when a
skill re-embeds catalogs or write-time templates that belong in `references/` / `templates/`,
duplicates a reference (dual residence), or would hollow hard gates into optional-only docs.
Objective shape signals are also enforced by `tools/doc_lint.py` (`shape` findings; thresholds
and allowlist policy documented in the thin-routing norm).

**cross-reference-auditor** — Check reference integrity:
- Find all `@skill-name` references in skills
- Verify each resolves to a corresponding skill under `src/` (family/name layout)
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

### Proposal Constraints (hard — do not deviate)

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

1. Create branch from up-to-date `main`: `evolve/YYYY-MM-DD`
2. All apply commits land on this branch only — never commit evolve proposals directly to `main`

### Iteration Loop

Run for `--iterate N` iterations (default: 5). Each iteration is one full detect→propose→validate→apply cycle.

```
for iteration in 1..N:
  1. Run gap detection on CURRENT state of src/** (respect scope)
  2. If no P1 or P2 gaps remain: stop early, report convergence
  3. Generate proposals for top --limit gaps
  4. Validate each proposal
  5. Apply validated proposals: edit files, commit individually
```

After all iterations (or early convergence), **do not stop**. Produce the final summary, then enter
**Completion** below.

### Final summary (before review)

Present: changes made, health score improvement, remaining gaps/recommendations, branch name, and
commit list. Then continue into Completion without waiting for a separate “please review” prompt
unless the user has already aborted.

## Completion (required — default path)

A run is **done** only when one of these terminal states is recorded:

| Terminal state | When |
|----------------|------|
| **merged** | Review APPROVE (or APPROVE after remediation); branch merged to `main`; history updated; branch deleted |
| **aborted** | User explicitly rejects landing (or discards all proposals); history updated; branch deleted or left only if user asks to keep it |
| **dry-run** | `--dry-run`: gap report only; no branch; no commits |

**Incomplete (forbidden as a stopping point):** “pending review”, unmerged `evolve/*` branch,
history left at pending after the session ends, or “hand off for later” without explicit abort.

### Completion steps (drive through these in order)

1. **History draft** — Append `history.md` entry for this run (score, iterations, branch, key
   changes, recommendations). Set **Status**: `in review` while landing. Commit on the evolve
   branch.
2. **Review** — Run `@workflow:review` on `main...HEAD` (standard depth unless the diff is
   tiny → quick). Emit a real verdict + evidence when integration-ready. Do not treat green
   `doc_lint` alone as reviewed.
3. **Remediate if needed** — On REQUEST CHANGES or unresolved findings: fix on the evolve
   branch (prefer one-file commits), re-run review until APPROVE **or** the user explicitly aborts.
4. **Land** — Merge into `main` (fast-forward preferred when possible). If project policy requires
   a PR, open it, merge it, and confirm `main` contains the tip. Do not leave an open PR as the
   session end state unless the user aborts further land steps.
5. **History finalize** — On `main`, set history **Status**: `merged` (include merge tip or date).
   Never leave stale `pending review` / `in review` after a successful land.
6. **Branch cleanup** — Delete the local `evolve/YYYY-MM-DD` branch. Delete the remote branch if
   one was pushed. Confirm no leftover evolve branch for this date.
7. **Publish** — If `src/**` changed, remind or run `./setup.sh` so installed agent trees match
   canonical (project convention).
8. **Report complete** — State terminal status (`merged` / `aborted`), final score, merge tip,
   and that the branch is gone.

### Abort (exception only)

Abort only on **explicit user direction** (e.g. “discard these changes”, “don't merge”, “stop”).

On abort:

1. Do **not** merge.
2. Update `history.md` **Status**: `aborted` with a one-line reason (commit on the branch if it
   still exists, or on `main` if history-only).
3. Default cleanup: delete the evolve branch after confirming the user does not need it. If they
   want to keep the branch for later, record that in history and still mark the **run** aborted
   (not “pending review”).
4. Report aborted — incomplete land is intentional.

Silence, session end, or “looks good” without merge is **not** abort — continue Completion.

### Zero-change runs

If detection finds no actionable P1/P2 and no proposals apply: no branch required (or delete an
empty branch). Optionally append a short history note (`no-op` / converged). Terminal state is
complete without merge.

## Integration Points

- Uses agent capability quick-references from `src/skills/references/agents/`
- Uses the embedded markup system defined in `src/skills/references/MARKUP.md` when proposing portable changes
- Operates under the `skills` meta-skill (`src/skills/SKILL.md`)
- **Review / land:** `@workflow:review` for the branch gate; git merge (or project PR flow) +
  branch delete for land — same completion bar as above
- **Run ledger / process lessons:** `@workflow` `references/runs-ledger.md`, compound `type: process`
  entries, `references/run-ledger-seeds.md` — seeds in; proposals out only via this skill
- **Process payload** (what runtimes must honor): `@workflow` `references/process-payload.md`
- **History log:** `history.md` in this skill directory — append-only run record; status must
  reflect the true terminal state (`merged` / `aborted` / dry-run note)
