---
name: workflow:review
description: Flexible code review for PRs, git ranges, files, or uncommitted changes
argument-hint: "[PR number, git range, file paths, or 'changes' for uncommitted]"
user-invocable: true
---

# Flexible Code Review

Review code changes with configurable depth — supports PRs, git ranges, specific files, or uncommitted changes.

## User Input

```text
$ARGUMENTS
```

## Target Detection

Parse input to determine review target:

| Input Pattern | Review Target | Action |
|--------------|---------------|--------|
| `123` or `#123` | Pull Request | `gh pr view 123` |
| `PR-123` or `pr 123` | Pull Request | `gh pr view 123` |
| `main..HEAD` | Git range | `git diff main..HEAD` |
| `main from tag 'v1.0' to HEAD` | Natural language range | Parse and convert to git range |
| `origin/main...feature` | Three-dot range | `git diff origin/main...feature` |
| `./src/` or `path/to/file` | Files/directories | Review specified paths |
| `changes` or empty | Uncommitted | `git diff` (staged + unstaged) |
| `staged` | Staged only | `git diff --staged` |

### Natural Language Parsing

Support human-readable range descriptions:

```
"main from tag 'production' to HEAD"
  -> git log production..HEAD

"changes since last release"
  -> git diff $(git describe --tags --abbrev=0)..HEAD

"commits on feature branch"
  -> git diff main...HEAD
```

## Setup Phase

### 1. Identify Changes

Run all git commands from the working directory. Do not use `git -C <path>` unless the working directory cannot be the
target repo.

```bash
# For PR
gh pr view $PR_NUMBER --json files,additions,deletions,title,body

# For git range
git diff --stat $RANGE
git log --oneline $RANGE

# For files/directories
git diff -- $PATHS
git status -- $PATHS

# For uncommitted
git status
git diff
git diff --staged
```

### 2. Understand Scope

Analyze changes to determine:
- Total files changed
- Lines added/removed
- Languages/technologies involved
- Affected components/layers
- Test coverage changes

### 3. Locate Plan and Acceptance Criteria (if available)

Resolve **planning root** first (`.agent-tools/planning/` preferred; else `./planning/` — @workflow
`references/planning-root.md`). Then:

```bash
ls <planning-root>/*/implementation-plan.md 2>/dev/null
ls <planning-root>/*/session-state.md 2>/dev/null
ls <planning-root>/*/requirements.md 2>/dev/null
```

**Determine requirements source**:
1. If `session-state.md` exists and has `requirements_source: pm` → use PM mode
2. If `session-state.md` exists and has `requirements_source: file` → use file mode
3. If `requirements.md` exists → file mode
4. If no `requirements.md` but a `work_item` is recorded in session state → PM mode
5. If reviewing a PR with issue references (e.g., `LIN-123`, `PROJ-456`) → fetch criteria from PM issue

**File mode**: Load acceptance criteria from `requirements.md`, Definition of Done and tasks from `implementation-plan.md`.

**PM mode**: Fetch acceptance criteria from the PM issue via Issue Retrieval Strategy from @workflow
(`planning/pm-integration.md`). Load DoD and tasks from `implementation-plan.md`.

**If no plan or criteria found**: Skip the acceptance-criteria agent — note absence in output.
On **feature** and **micro** tracks with ACs available, acceptance-criteria check is **mandatory**
for standard+ depth (and for micro quick when ACs exist — single agent may combine AC + quality).

### 4. Select Review Depth (infer; do not ask by default)

Depth changes **dose**, not the review gate. Green tests ≠ reviewed. Evidence schema always
required for continue integrate (`gates.md`).

**Resolution order** (first hit wins):

1. User flag in `$ARGUMENTS`: `--depth quick|standard|deep` or words `quick` / `standard` / `deep`
2. Session-state `track:` or continue context — @workflow `references/tracks.md`:
   - **micro** → `quick`
   - **feature** → `standard` (or `deep` if security-sensitive paths / large diff)
   - **research** spike with code → `quick` or `standard` by size
3. Diff heuristics when no track:
   - **Quick** — small changes (&lt;100 lines, &lt;5 files), obvious bugfix
   - **Standard** — most reviews
   - **Deep** — large/complex, security-sensitive paths (auth, crypto, payments, migrations)

**State the chosen depth in one line** and proceed. Ask to confirm **only** when ambiguous
between standard and deep, or user previously required always-confirm in conventions.

| Depth | Agents (see menus) |
|-------|---------------------|
| **Quick** | 2 |
| **Standard** | 5 |
| **Deep** | 8+ |

**Optional mode extras** (additive, not depth): path-triggered **security** emphasis; structural
**architecture** when layer boundaries move — covered in agent menus / special-modes.

**Load agent menus:** `references/agent-menus.md` for the chosen depth (role lists, synthesis/critic pass).
For review criteria standards, also reference @workflow (`execution/quality-checkpoints.md`).

**Continue integration:** map verdict to unit events — APPROVE → evidence + `REVIEW_CLEAN`;
REQUEST CHANGES (code) → `REVIEW_FINDINGS_CODE`; structural → `REVIEW_FINDINGS_STRUCTURAL`.
Swarm reviewer statuses `APPROVED` / `FIX_REQUESTED` use the same evidence bar
(@workflow `references/handoff-package.md`).

## Findings Structure

### Priority Classification

**P1 - Critical (Blocks Merge)** — security, data corruption, breaking changes, critical bugs

**P2 - Important (Should Fix)** — performance, architecture, code quality, missing tests

**P3 - Nice to Have (Optional)** — style, minor optimizations, docs, optional refactors

### Finding Format

```markdown
### [P1/P2/P3] [Category]: [Title]

**Location**: `file/path.ext:line`

**Issue**:
[Description]

**Impact**:
[Why this matters]

**Suggestion**:
[How to fix]

**Code Example** (if helpful):
```[language]
# Before
[problematic code]

# After
[suggested fix]
```
```

## Review Output

When emitting the summary, verdict, and next steps, **load and use** `templates/review-report.md`.

Verdict options:

- **APPROVE** — No P1 issues, all acceptance criteria met (if plan available)
- **REQUEST CHANGES** — P1 issues or unmet acceptance criteria
- **COMMENT** — Suggestions but no blockers

## Special Review Modes

For pre-commit, deployment-range, or security-focused variants, **load** `references/special-modes.md`.

## Integration Points

### With PR Comments (if PR target)

Offer to post findings as a PR comment (yes/local-only).

### With /workflow:plan and /workflow:execute

Review loads acceptance criteria to verify completeness — not just code quality. Unmet criteria are P1 (blocking).

### With /workflow:compound

If significant issues found and fixed, offer `/workflow:compound`.

### With Session State

If reviewing during execute/continue, findings inform session notes. Prefer recording valid
evidence line on session-state or PM (`gates.md` schema). Optional structured return fields:
@workflow `references/handoff-package.md`.

### With runs ledger

Continue host records review phase-return + fidelity; review skill need not write
`.agent-tools/runs/` itself when invoked under continue.

## Quality Principles

### Own the change (human guidance; system eases)

Review is **code-centric**. There is no robotic “read N% of LOC” rule. Depth is risk- and
track-scaled (`quick` / `standard` / `deep`). Prefer:

- **Always:** intent, blast radius, rollback story are coherent with ACs/plan  
- **Pattern / seam read:** does the PR match accepted patterns from design/research, or revive
  rejected legacy paths? Signal prefactor or re-enter refine/plan when structure is wrong  
- **Never:** treat green tests alone as “reviewed,” or approve production changes with no
  code-bearing pass  

Early design/structure alignment should reduce surprise volume so this pass stays high-signal.
Full craft: @workflow `references/context-engineering.md` › Code ownership.

### Reasoning Rigor

Every finding must be grounded in evidence, not intuition:

- **Cite evidence** — specific `file:line`. If you can't point to a location, you haven't verified.
- **Trace, don't assume** — follow calls to actual definitions; names can be shadowed or framework-wrapped.
- **Check the opposite hypothesis** — before P1/P2, ask what would make the code correct; downgrade if refuted.
- **Distinguish crash sites from root causes** — trace to where incorrect behavior begins.

### Focus on Impact

- P1 blockers; P2 quality; P3 suggestions — don't overwhelm with minor issues.

### Be Constructive

- Explain why; provide concrete suggestions; acknowledge good practices; focus on code not author.

### Scale Appropriately

- Quick for small; deep for critical paths; don't over- or under-review.

## Common Patterns

For domain-specific checklists (DB, API, security, UI), **load** `references/common-patterns.md`.
