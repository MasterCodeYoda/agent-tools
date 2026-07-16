---
name: workflow:refine
description: Discover and refine requirements through guided conversation
argument-hint: "[optional: initial feature idea or problem description]"
user-invocable: true
---

# Requirements Discovery and Refinement

Transform ideas into clear requirements through guided conversation.

## User Input

```text
$ARGUMENTS
```

## Input Interpretation

Parse input to determine discovery mode:

| Input Pattern                          | Interpretation                       |
|----------------------------------------|--------------------------------------|
| Empty                                  | Prompt for initial description       |
| `./planning/<project>/brainstorm.md`   | Start from a brainstorm seed concept (see `/workflow:brainstorm`) |
| `./planning/<project>/requirements.md` | Refine existing requirements (file mode) |
| `continue`                             | Resume in-progress refinement        |
| `LIN-[0-9]+` or `[A-Z]+-[0-9]+`       | Refine existing PM issue (PM mode)   |
| PM issue URL                           | Refine existing PM issue (PM mode)   |
| Text                                   | Start discovery with initial context |

**If input is empty**, ask: "What feature or problem would you like to explore? Describe the idea, user need, or problem
you're trying to solve."

**If path to existing requirements.md**, load and review for refinement.

**If a `brainstorm.md` exists** for the project (or is passed explicitly), use its Seed Concept and
Open Questions for Refinement as the starting context for Phase 1 — the fuzzy framing is already
done, so begin discovery from the chosen direction rather than from scratch.

**Altitude (light):** if the request is clearly a **multi-unit unordered program** (several
independently claimable workstreams, no map), **offer** `/workflow:roadmap` once and wait — do not
hard-block refine if the user wants requirements for a single named unit anyway.

**If `continue`**, check for `./planning/*/requirements.md` with `Status: Draft` (file mode) or in-progress PM issues
(PM mode) and resume.

**If issue key or PM URL**, fetch issue details using the Issue Retrieval Strategy from @workflow (PM integration).
Use the existing issue content as starting context for refinement.

**When conducting problem discovery**, use the `AskUserQuestion` tool, if available, to guide the user through the
information gathering process. If such a tool is not available, ask the user questions one at a time, or in small groups
of questions that are interrelated, waiting for their answer after each question before proceeding. Ask followup
questions when necessary.

## Requirements Source Mode

Determine whether this refinement uses **file mode** or **PM mode**. Follow the detection logic from @workflow
(`planning/pm-integration.md`):

1. **Explicit invocation**: Issue key or PM URL → PM mode. File path → file mode.
2. **Project context**: Check AGENTS.md, CLAUDE.md, `.claude/settings.json` for PM system indicators. If found and
   invocation is ambiguous (empty or text input), default to PM mode.
3. **Available MCP tools**: Linear/Jira MCP tools present → suggest PM mode.
4. **Fallback**: File mode.

State the determination to the user and allow course correction:
> "I'll use [PM mode / file mode] for this refinement. [Reason]. Say 'use [other] mode' if you'd prefer."

## Decomposition Mode Selection

Refinement output shape depends on decomposition mode (selection criteria in @workflow; full doctrine in @workflow (`references/decomposition-modes.md`)):

- **Vertical-slice mode** — refinement produces user stories that each ship a feature increment end-to-end. Phase 3 output is "As a [user], I want…" stories with shared acceptance criteria.
- **Deliverable-partition mode** — refinement produces a sub-issue breakdown where each sub-issue owns a verbatim subset of the parent epic's acceptance criteria. Phase 3 output is a deliverable list + AC traceability matrix, not user stories.

### Mode Detection

1. **Explicit invocation**: User says "use vertical-slice mode" or "use deliverable-partition mode" → that mode.
2. **Work shape heuristics**: User-facing feature in deployed system → vertical-slice. Greenfield scaffolding, validators, CI/CD, base contracts, contract-first changes, compliance/migration roll-outs → deliverable-partition.
3. **Fallback**: Vertical-slice for ambiguous feature work; deliverable-partition for ambiguous foundation/infrastructure work.

State the determination to the user and allow course correction:
> "I'll use [vertical-slice / deliverable-partition] mode for this refinement. [Reason]. Say 'use [other] mode' if you'd prefer."

In deliverable-partition mode, **skip Phase 3 (User Stories) and run Phase 3-D (Deliverable Breakdown) instead**. All other phases apply identically.

## Phase 1: Problem Discovery

### Understand the Problem Space

Ask clarifying questions to understand:

1. **Who has this problem?** — users affected, role/context
2. **What's happening now?** — current handling, pain
3. **What triggers the need?** — when it occurs, worse situations
4. **What's the impact?** — if unsolved; time/effort wasted

### Capture Problem Statement

Synthesize a clear problem statement. **Load** `templates/problem-statement.md` for the shell.
Confirm with user: "Does this capture the core problem?"

## Phase 2: Solution Exploration

### Explore Potential Approaches

Discuss: ideal unconstrained solution; MVP; similar solutions/patterns; constraints (tech, time, org).

### Capture Proposed Solution

**Load** `templates/proposed-solution.md` for the shell (approach, why, alternatives).
Confirm: "Does this approach feel right for solving the problem?"

### Coherence check against the decision corpus

Before finalizing, scan the project's decision records (`docs/decisions/`, README `## Decisions`, or
`planning/conventions.md` mapping). If this **changes** an existing decision, plan to **rewrite that
record** at close — not add a competing one — and surface the conflict now. Capture rationale +
rejected alternatives. See @workflow (`references/decision-records.md`).

## Phase 3: User Stories (vertical-slice mode)

### Extract Key User Needs

For each distinct user need, create a user story:

- As a [user], I want [capability] so that [benefit]

Group into Core (must have) vs Supporting (nice to have). Ask about other user types and the
most important story.

## Phase 3-D: Deliverable Breakdown (deliverable-partition mode)

Replace Phase 3. Output: deliverable list + AC traceability matrix.

### Identify Deliverables

List discrete artifacts (not layers). Ask what the epic produces, bundling, dependency order.

### Partition Acceptance Criteria

Every parent AC owned by exactly one deliverable. **Load** `templates/ac-traceability.md` for the matrix shell.
Confirm coverage and unambiguous ownership.

### Sub-issue Definition

For each deliverable: name + scope; **inherited parent ACs verbatim**; tasks; `blocks` /
`blocked_by` / `parallelizable_with`; per-deliverable DoD per @workflow
(`execution/quality-checkpoints.md`). Full deliverable-partition template: @workflow
(`planning/templates.md`).

### Gap-prevention Confirmation

- [ ] Every parent AC in exactly one sub-issue
- [ ] Inherited AC text verbatim
- [ ] Dependency order recorded

Ask about deferred ACs needing tracking issues.

## Phase 3.5: Dependency Metadata

When refinement produces **more than one item**, capture for each:

| Field | Meaning |
|-------|---------|
| `blocks` | Items that cannot start until **this** item completes |
| `blocked_by` | Items that must complete before **this** item can start |
| `parallelizable_with` | Peers safe to run **concurrently** (no shared files / ordering) |

`blocks` / `blocked_by` are inverses — record both consistently. Skip for single-item refinement.

**Where written:** file mode → Dependencies block in `requirements.md`; PM mode → native
blocks/blocked-by relations; `parallelizable_with` as note/label.

## Phase 4: Requirements Organization

Separate Must-Have / Nice-to-Have / Out of Scope with brief why. Ask: "If we could only ship one
thing?" and "What can we explicitly defer?"

## Phase 4.5: Leverage Check

Before finalizing: is there one addition/removal/reframe that disproportionately increases value
vs effort? If yes, present What / Why / Trade-off and ask. If nothing, proceed silently.

## Phase 4.6: Pressure-Test (optional)

**Gate:** only when cost of being wrong is high *and* requirements contested/circled. Skip routine work.

When gated: advisor sub-agents — First-Principles, Contrarian, Outsider — then Critic Pass Blind-Spot
(@workflow `references/critic-pass.md`). Fold survivors into must-haves / open questions; user decides
high-impact reframes.

## Phase 5: Success Criteria

Define measurable Functional / Quality / Business outcomes (checkbox-ready). Ask how we know it works
and what success vs "done" means.

## Phase 6: Capture Open Questions

Document unknowns (stakeholder, technical, later decisions) as checkboxes. Ask what still must be
answered before/during implementation.

## Capture Requirements

### Determine Project Name

```bash
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

Or ask user if unclear.

### Create Planning Directory

```bash
mkdir -p ./planning/<project>/
```

Created in both modes for later plan/session-state.

### File Mode: Generate requirements.md

**Only in file mode.** Write `./planning/<project>/requirements.md` using
**`templates/requirements.md`** (load that file; fill from phases above).

### PM Mode: Write Requirements to PM Issue

**Only in PM mode.** Update or create the PM issue — no `requirements.md`.
MCP calls and field mappings: @workflow (`planning/pm-integration.md`).
Description structure: same reference (Issue Update section).
Multi-item dependencies → native relations + parallelizable_with note/label.

## PM Tool Integration (file mode only)

**Skip entirely in PM mode.** After saving `requirements.md`, optionally offer tracking-issue
creation. **Load** `references/pm-file-mode-offer.md` for the offer UI and example createIssue
shapes (prefer @workflow `planning/pm-integration.md` for authoritative field mappings).

## Completion

Present summary using **`templates/completion-file.md`** (file mode) or
**`templates/completion-pm.md`** (PM mode).

## Key Principles

### Discovery Over Documentation

- Focus on understanding the problem; documentation captures understanding
- Questions beat assumptions

### Conversation Is the Tool

- Guide through questions, not templates; adapt; skip irrelevant phases

### Minimum Viable Requirements

- Enough to plan; don't over-specify emergent details; mark unknowns

### Separate Concerns

- Requirements = what/why; planning = how; this command is requirements only
