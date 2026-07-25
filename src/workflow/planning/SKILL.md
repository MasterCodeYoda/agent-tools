---
name: workflow:plan
description: Create implementation plans from requirements
argument-hint: "[--worktree] [requirements.md path, work item ID (LIN-123, PROJ-456), or feature description]"
user-invocable: true
---

# Implementation Planning

Transform requirements into actionable implementation plans with task breakdowns and technical decisions.

**Note**: For discovering and refining requirements, use `/workflow:refine` first. This command expects clear
requirements as input.

## User Input

```text
$ARGUMENTS
```

## Flag Extraction

Before interpreting input, extract the `--worktree` flag if present:

1. **Check for `--worktree`** in `$ARGUMENTS`
2. If found, set `WORKTREE_MODE=true` and strip `--worktree` from `$ARGUMENTS` before passing to Input Detection
3. If not found, set `WORKTREE_MODE=false`

**Validation** (stop with error if any fail):

- **Already inside a worktree**: If `git rev-parse --show-toplevel` differs from the main repo root (i.e., CWD is already a worktree), error:
  ```
  ERROR: Already inside a git worktree. Cannot nest worktrees.
  Run /workflow:plan without --worktree from this worktree.
  ```

**If input is empty**, check for existing context based on requirements source mode (see below):

- **File mode**: Look for `./planning/*/requirements.md` files. If found, list them and ask which to plan.
- **PM mode**: Prompt for an issue key or check project context for recent issues.
- **If neither found**, ask: "What would you like to plan? Provide a requirements.md path, work item ID, or describe the
  feature."

## Input Detection

Parse input to determine source type:

| Pattern                                | Source Type         | Action                                                       |
|----------------------------------------|---------------------|--------------------------------------------------------------|
| `./planning/<project>/requirements.md` | Requirements doc    | Load requirements, create implementation plan                |
| `./planning/<project>/`                | Planning directory  | Load requirements.md from directory                          |
| `LIN-[0-9]+`                           | Linear issue        | Fetch via Issue Retrieval Strategy — treat as requirements    |
| `[A-Z]+-[0-9]+`                        | Jira ticket         | Fetch via Issue Retrieval Strategy — treat as requirements    |
| `http(s)://`                           | URL                 | Fetch via Issue Retrieval Strategy if PM URL, else WebFetch — treat as requirements |
| Directory path                         | Existing plan       | Load and review                                              |
| Text                                   | Feature description | Use directly (suggest /workflow:refine for complex features) |

**For text input**: If the description is vague or complex, suggest: "This sounds like it might benefit from
requirements discovery. Would you like to run `/workflow:refine` first to clarify requirements?"

## Requirements Source Mode

Determine whether this planning session uses **file mode** or **PM mode**. Follow the detection logic from
@workflow (`planning/pm-integration.md`):

1. **Explicit invocation**: Issue key or PM URL → PM mode. File path (requirements.md or planning directory) → file mode.
2. **Existing artifacts**: If `./planning/<project>/requirements.md` exists → file mode. If absent and an issue key is
   available → PM mode.
3. **Project context**: Check AGENTS.md, CLAUDE.md, `.claude/settings.json` for PM system indicators. If found and
   invocation is ambiguous, default to PM mode.
4. **Available MCP tools**: Linear/Jira MCP tools present → suggest PM mode.
5. **Fallback**: File mode.

State the determination to the user and allow course correction.

## Decomposition Mode Selection

Implementation plan shape depends on decomposition mode (selection criteria in @workflow; full doctrine in @workflow (`references/decomposition-modes.md`)):

- **Vertical-slice mode** — plan is organized as Vertical Slice Breakdown (Domain → Application → Infrastructure → Framework per slice).
- **Deliverable-partition mode** — plan is organized as Deliverable Breakdown (per-deliverable task list with verbatim parent-AC ownership in each sub-issue).

### Mode Detection

1. **Inherit from refinement**: If requirements were produced by `/workflow:refine` and a mode was recorded, use that mode.
2. **Explicit invocation**: User specifies "use vertical-slice mode" or "use deliverable-partition mode".
3. **Work shape heuristics**: User-facing feature in deployed system → vertical-slice. Greenfield scaffolding, validators, CI/CD, base contracts, contract-first changes, compliance/migration roll-outs → deliverable-partition.
4. **Fallback**: Vertical-slice for ambiguous feature work; deliverable-partition for ambiguous foundation/infrastructure work.

State the determination to the user and allow course correction:
> "I'll plan in [vertical-slice / deliverable-partition] mode. [Reason]. Say 'use [other] mode' if you'd prefer."

Use the Variant A/B breakdown template from @workflow (`planning/templates.md`) › Implementation Plan Document Template matching the selected mode.

## Context Gathering

### 1. Auto-Detect Project Context

```bash
# Check for existing planning
ls ./planning/ 2>/dev/null

# Get project name from git or directory
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Check for PM tool configuration
cat .claude/settings.json 2>/dev/null | grep project_management
```

### 2. On-demand codebase research + design confirm (default)

**Load** @workflow (`references/context-engineering.md`) › On-demand codebase research,
Technical design discussion, and Plan segmentation.

This is **not** the research *track*. Prefer research and technical design already produced
in **`/workflow:refine`**. Plan **re-verifies** and fills gaps; it does not silently invent a
second product truth.

1. **Load existing** `codebase-research.md` and `design-discussion.md` when present.  
2. **Freshness:** discard/re-run research if the branch moved or research is wrong — prefer
   **questions-first + ticket-hidden facts** (hide solution intent in the research window).  
3. **If research missing** on non-trivial work: run full/light research now (sub-agents for
   search; parent keeps digest); write `./planning/<project>/codebase-research.md`.  
4. **If design missing** on feature/hard work: produce `design-discussion.md` **before**
   structure/tactical plan — or **stop and offer re-enter refine** when ACs must change.  
5. **If design invalidates frozen ACs:** do **not** quietly rewrite acceptance criteria in the
   plan — stop and offer `/workflow:refine`.  
6. **Human leverage:** present short research + design confirm before or with the segmented
   plan draft. Wrong research/design → throw out and re-steer.

**Also gather:**

**Requirements Analysis**:

- Parse work item details
- Extract acceptance criteria
- Identify stakeholders
- Note constraints and dependencies
- Confirm requirements already **converged** with research (refine primary)

**Technical Research** (if needed — external docs, not a substitute for codebase research):

- Framework documentation
- Best practices
- Security considerations
- Performance implications

### 3. Prefactoring Assessment

Using the **Codebase Analysis** output above, ask one question before breaking down the
change: *given the current shape of the code, is the change hard?* If a behavior-preserving
structural refactor would make the upcoming change small and safe, that refactor is
**prefactoring** — "make the change easy, then make the easy change" (Kent Beck, *Tidy First*).

When prefactoring applies, capture it as **enabling work** that runs first (see Implementation
Order). Hold it to these guardrails:

- **Behavior-preserving** — no functional change; existing tests stay green and no new
  behavioral tests are needed (add characterization tests first only if coverage is missing).
- **Separately committed** — structural changes never share a commit with behavioral changes.
- **Justified by this change** — the refactor must make *this* upcoming work easier. No
  speculative cleanup of code the change doesn't touch.
- **Off-ramp** — if the change is already easy against the current code, skip this; there is no
  prefactoring step by default.

## Load Requirements

### From requirements.md (file mode)

If requirements source is file mode:

1. Read the requirements document
2. Extract key information:
    - Problem statement / overview
    - User stories
    - Must-have vs nice-to-have requirements
    - Success criteria
    - Related issue IDs
    - **Dependency metadata** — any per-item `blocks` / `blocked_by` /
      `parallelizable_with` from the requirements' `Dependencies` section (written by
      `/workflow:refine` Phase 3.5)

### From Work Item (PM mode)

If requirements source is PM mode:

1. Fetch issue details using the Issue Retrieval Strategy from @workflow (PM integration)
2. Extract requirements from title, description, and acceptance criteria
3. Note the issue ID for linking
4. **Read issue relations** — capture native "blocks" / "blocked by" links and any
   `parallelizable_with` note/label as dependency metadata
5. Do not look for or warn about missing `requirements.md`

### Review with User

Present requirements summary and ask:

1. "Do these requirements look complete for planning?"
2. "Any clarifications needed before creating the implementation plan?"
3. "Should we run `/workflow:refine` first to clarify requirements?"

**Surface dependency declarations.** Echo back the `blocks` / `blocked_by` /
`parallelizable_with` relationships found (or note their absence) and let the user confirm or
adjust. These are written to the plan's frontmatter (below) so downstream orchestration
(`/swarm`) can schedule parallel waves safely.

Proceed to implementation planning once requirements are confirmed.

## Implementation Plan

For task breakdown patterns, see @workflow (`planning/task-breakdown.md`).
For plan density and **hard segmentation**: @workflow
(`references/context-engineering.md`) › Plan segmentation.

### Create Implementation Plan

**Do not write files to disk yet** — present for approval first (§Plan Approval Gate).
Exception: you may write `codebase-research.md`, `design-discussion.md`, and (per visual rules)
`visual-plan.html` before approval when that improves human review of the draft.

Target: `./planning/<project>/implementation-plan.md`

**Load and fill** @workflow (`planning/templates.md`) › **Implementation Plan Document Template**
(frontmatter with `blocks` / `blocked_by` / `parallelizable_with`, Approach, **Research
grounding**, **Design**, **Structure outline**, **Intended changes (snippets)**, Breakdown
through Definition of Done, Variant A vertical-slice or Variant B deliverable-partition
breakdown). Empty dependency lists when none.

**Hard segmentation (do not weaken)** — substantial / multi-file plans (default unless truly
trivial). **Do not** race to a finished tactical plan body without structure:

1. **Design confirm** — link `design-discussion.md` (or light design / skip reason); state that
   design still holds or stop for refine.  
2. **Structure outline** — vertical phases (or deliverable order), signatures/seam shape as
   needed, **verification after each phase** — this is the **human deep-read** surface.  
3. **Intended changes (tactical)** — paths + snippets / before→after; **human spot-check**.  
4. **Breakdown + DoD** — tasks under the structure, not a horizontal layer dump when in
   vertical-slice mode.

**Quality bar:**

- Cite research + design under Research grounding / Design  
- Structure must be **vertical** checkpoints unless deliverable-partition mode applies  
- Tactical snippets + per-step verification for non-obvious edits  
- Sweet spot: structure scannable in one sitting; tactics reliable for a weaker implementer  

In deliverable-partition mode the breakdown carries parent ACs, AC traceability matrix, verbatim AC
inheritance per sub-issue, and gap-prevention before parent epic close.

### Initialize Session State

**Do not write until approved.** Target: `./planning/<project>/session-state.md`.

**Load** Session State Template (plan-time) from @workflow (`planning/templates.md`):
`session_count: 0`, `status: planned`, progress zeros, Status awaiting approval, Next Steps → execute.

## PM Tool Integration

For PM-specific workflows, reference @workflow (PM integration)

### Update Work Item (after approval)

**Do not update PM tools until the user approves the plan** (see §Plan Approval Gate). Once approved, apply the plan-time status update for the detected PM tool — status → In Progress plus a planning-complete comment/link. The Linear/Jira MCP calls and the manual fallback live in @workflow (`planning/pm-integration.md`) › Plan-Time Status Update.

## Leverage Check

Before presenting the plan for approval, review the slices and task breakdown holistically:

**Ask yourself**: Is there one reordering, simplification, or addition that would significantly increase value or reduce risk?

If a high-leverage insight surfaces:

1. Incorporate it into the plan
2. Add a **Key Insight** callout in the plan summary presented to the user:
   ```markdown
   ### Key Insight
   [Description of the high-leverage change and why it matters]
   ```

If nothing surfaces, proceed without comment — this step should add signal, not noise.

## Visual Plan Approval Surface (optional)

After the draft implementation plan is complete and the leverage check is done — **before** the
Plan Approval Gate — optionally publish a **static HTML visual plan** so the user can review
direction more easily in a browser.

**Load and follow** @workflow (`planning/references/visual-approval.md`). Summary contract:

- **Presentation only.** The visual plan is an approval aid. It does **not** replace
  `implementation-plan.md` as the executable source of truth for execute, continue, or swarm.
- **First-party static HTML.** Author `planning/<project>/visual-plan.html` from
  @workflow (`planning/templates/visual-plan.html`). No third-party Plan apps, MCP, or CLIs.
- **Convention-gated (additive).** Honor `planning/conventions.md` › Visual plan approval when
  that section exists (`never` | `on-substantial` | `always`). **Missing section keeps the
  built-in default `on-substantial`** — other project overrides (merge policy, tracks, PM) do
  not turn visual plan off. See @workflow (`planning/references/visual-approval.md`).
- **Non-blocking.** Non-substantial plan, policy `never`, or write failure → record
  `visual_plan: skipped — <reason>` and proceed to the approval prompt. Never block the gate.
- **Same content.** Build the HTML **from** the in-memory draft implementation plan
  (design confirm, **structure outline**, task breakdown, files, decisions, risks,
  intended-change snippets, verification) **and** ground architecture/file maps in
  `codebase-research.md` / design so approval is of one plan, not two competing ones. See
  context-engineering › Visual plan fit — **surface segmentation**, do not flatten.
- **Pre-approval write exception:** you may create the project planning directory and write
  **only** `visual-plan.html` before Approve. Still do not write `implementation-plan.md` or
  `session-state.md` until the user chooses Approve.
- **Link, don’t auto-launch.** On success, print absolute path + `file://` markdown link in
  this turn. Do **not** run `open` / `xdg-open` unless the user explicitly asks (or says yes
  to an optional open offer). Full rules: visual-approval reference.

On success, keep the absolute path and `file://` link for the approval prompt and for
session-state after approve.

## Plan Approval Gate

**Load and follow** `references/plan-approval.md` end-to-end: hard refuse until approve,
approval = proceed-with-hypothesis, present options, revise loop, save steps, parallel prompt,
execute handoff.

**Hard refuse:** do not execute, save plan/session-state, or update PM until explicit approve.

## Quality Checklist (before present)

- [ ] Requirements/ACs clear; scope explicit  
- [ ] Research + design (or skip reasons); structure outline + tactical snippets as required  
- [ ] Tasks complete (no optional tiers); risks noted  
- [ ] Visual plan attempted or skipped; plan presented for approval  

## Integration

`/workflow:refine` → requirements · `/workflow:execute` → plan + session-state · visual
`planning/references/visual-approval.md` · PM `planning/pm-integration.md` · audit P1s as
next-cycle requirements.
