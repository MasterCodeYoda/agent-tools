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

1. **Who has this problem?**
    - Who are the users affected?
    - What's their role or context?

2. **What's happening now?**
    - How do users currently handle this?
    - What's painful or inefficient?

3. **What triggers the need?**
    - When does this problem occur?
    - What situations make it worse?

4. **What's the impact?**
    - What happens if this isn't solved?
    - How much time/effort is wasted?

### Capture Problem Statement

Synthesize a clear problem statement:

```markdown
## Problem Statement

[User type] experiences [problem] when [context/trigger].
Currently, they [workaround], which results in [negative outcome].
```

Confirm with user: "Does this capture the core problem?"

## Phase 2: Solution Exploration

### Explore Potential Approaches

Discuss possible solutions:

1. **What would ideal look like?**
    - If constraints didn't exist, what would you build?

2. **What's the minimum viable solution?**
    - What's the smallest change that would help?

3. **What similar solutions exist?**
    - Are there patterns we can follow?
    - What have others done?

4. **What constraints exist?**
    - Technical limitations?
    - Time or resource constraints?
    - Organizational considerations?

### Capture Proposed Solution

```markdown
## Proposed Solution

[High-level approach description]

### Why This Approach

- [Reason 1]
- [Reason 2]

### Alternatives Considered

- [Alternative 1]: [Why not chosen]
- [Alternative 2]: [Why not chosen]
```

Confirm: "Does this approach feel right for solving the problem?"

### Coherence check against the decision corpus

Before finalizing, scan the project's decision records (the decision layer — `docs/decisions/`, a README `## Decisions` section, or wherever `planning/conventions.md` maps it) for any record this requirement contradicts or duplicates. If it **changes** an existing decision, plan to **rewrite that record** at close — not to add a competing one — and surface the conflict to the user now. The rationale + rejected alternatives captured above are what the rewritten record needs: capture "the why" here or nowhere. See @workflow (`references/decision-records.md`).

## Phase 3: User Stories (vertical-slice mode)

### Extract Key User Needs

For each distinct user need, create a user story:

```markdown
## User Stories

### Core Stories (Must Have)

- As a [user], I want [capability] so that [benefit]
- As a [user], I want [capability] so that [benefit]

### Supporting Stories (Nice to Have)

- As a [user], I want [capability] so that [benefit]
```

Ask:

- "Are there other user types who would use this?"
- "What's the most important story - the one that defines success?"

## Phase 3-D: Deliverable Breakdown (deliverable-partition mode)

In deliverable-partition mode, replace Phase 3 with this phase. The output is a deliverable list + AC traceability matrix that downstream sub-issues will consume.

### Identify Deliverables

List the artifacts the epic must produce. Each deliverable is a discrete artifact (a library scaffold, a validator rule set, a CI pipeline, a hook installer, a documentation page, a contract type), not a layer or a user-visible increment.

Ask:

- "What artifacts does this epic produce when complete?"
- "Are any of these artifacts naturally bundled (one sub-issue) or naturally separate (multiple sub-issues)?"
- "What's the dependency order between deliverables?"

### Partition Acceptance Criteria

For each parent acceptance criterion, identify the deliverable that owns it. Every parent AC must be owned by exactly one deliverable — no orphans, no shared ownership.

Capture as a traceability matrix:

```markdown
## AC Traceability Matrix

| Parent AC | Owning sub-issue | Verified at |
|-----------|------------------|-------------|
| AC1 | Sub-issue 1 (Library scaffold) | Sub-issue 1 close |
| AC2 | Sub-issue 2 (Validator rules) | Sub-issue 2 close |
| AC3 | Sub-issue 1 (Library scaffold) | Sub-issue 1 close |
```

Ask:

- "Every parent AC needs to live in exactly one sub-issue — does this partition cover all of them?"
- "Any AC where ownership is genuinely ambiguous? (If yes, that's a sign the AC itself may need refinement before partitioning.)"

### Sub-issue Definition

For each deliverable, draft a sub-issue body containing:

- Deliverable name + scope
- **Inherited parent ACs (verbatim, no paraphrasing)** — verified at this sub-issue's close
- Sub-issue-specific tasks
- Dependencies on other sub-issues — captured as `blocks` / `blocked_by` /
  `parallelizable_with` (see Phase 3.5)
- Per-deliverable Definition of Done (per @workflow `execution/quality-checkpoints.md`)

The full Deliverable-Partition Template lives in @workflow (`planning/templates.md`).

### Gap-prevention Confirmation

Before completing this phase, confirm:

- [ ] Every parent AC appears in exactly one sub-issue.
- [ ] Every inherited AC text is verbatim (not paraphrased).
- [ ] Sub-issue dependency order is recorded.

Ask: "Any deferred AC needs a tracking issue + explicit approval. Any in this epic, or are all parent ACs covered?"

## Phase 3.5: Dependency Metadata

When refinement produces **more than one item** (multiple user stories in vertical-slice
mode, or multiple sub-issues in deliverable-partition mode), capture the dependency
relationships between them. This metadata lets downstream orchestration (`/swarm`) schedule
items in parallel waves safely; for single-agent `/workflow` it documents sequencing.

For each produced item, capture three fields:

| Field | Meaning |
|-------|---------|
| `blocks` | Items that cannot start until **this** item completes |
| `blocked_by` | Items that must complete before **this** item can start |
| `parallelizable_with` | Peer items that can safely run **concurrently** with this one (no shared files / no ordering constraint) |

Guidance:

- `blocks` / `blocked_by` are inverses — if A blocks B, then B is blocked_by A. Record both
  directions for clarity; keep them consistent.
- `parallelizable_with` is an explicit safety signal: only list peers when you're confident
  they don't touch the same files and have no ordering dependency.
- If an item is independent, `blocks`/`blocked_by` are empty and it is parallelizable with
  any other independent item.

Ask only what isn't already implied by the decomposition (deliverable-partition sub-issues
often already state their dependency order in Phase 3-D — reuse it). Skip this phase entirely
for a single-item refinement.

**Where this metadata is written** (see the output sections below):

- **File mode** → a per-item `Dependencies` block inside `requirements.md`.
- **PM mode** → native issue relations (Linear/Jira "blocks" / "blocked by") where the tool
  supports them; record `parallelizable_with` as an issue note/label since most PM tools
  have no native field for it.

## Phase 4: Requirements Organization

### Separate Must-Have from Nice-to-Have

```markdown
## Key Requirements

### Must Have

- [Essential requirement] - [why essential]
- [Essential requirement] - [why essential]

### Nice to Have

- [Optional enhancement] - [value it adds]
- [Optional enhancement] - [value it adds]

### Out of Scope

- [Explicitly excluded] - [why excluded]
```

Ask:

- "If we could only ship one thing, what would it be?"
- "What can we explicitly defer to a future iteration?"

## Phase 4.5: Leverage Check

Before finalizing requirements, pause and assess:

**Ask yourself**: Is there one addition, removal, or reframing of the requirements that would disproportionately increase the value delivered relative to effort?

If yes, present it to the user:

- **What**: The proposed change
- **Why**: How it increases value disproportionately
- **Trade-off**: What it costs (scope, complexity, time)

Ask: "Before we finalize, I noticed a potential high-leverage opportunity: [description]. Would you like to incorporate this, or keep the current scope?"

If nothing surfaces, proceed without comment — this step should add signal, not noise.

## Phase 4.6: Pressure-Test (optional)

**Gate**: run this only when the cost of being wrong is high *and* the requirements have been
contested or circled — an irreversible choice, a disputed scope, an expensive bet. Skip routine
refinements; like the Leverage Check, this step adds signal, not noise. Requirements shaped by
guided conversation tend to inherit the user's framing, so this is the cheapest point in the
pipeline to catch a flawed assumption before it propagates into the plan.

When the gate is met, pressure-test the draft requirements (must-haves, scope, success
direction) with a small panel of advisor sub-agents, each applying one distinct lens:

- **First-Principles** — are we solving the right problem, or optimizing the wrong variable?
- **Contrarian** — what failure mode or fatal flaw does this scope miss?
- **Outsider** — with no shared context, what won't land or doesn't make sense?

(Expansionist and Executor lenses are already covered by Phase 4.5 and Phase 5 respectively — do
not duplicate them here.)

Then run **Pass 1 (Blind-Spot)** of the Critic Pass — see @workflow
(`references/critic-pass.md`) — over the panel's responses to surface what *all* the advisors
missed. Do not anonymize: a single model role-playing the lenses gains little from a shuffle, so
the value is in the lenses and the blind-spot round, not in hiding their authorship.

Fold what survives into the must-haves (Phase 4) and Open Questions (Phase 6); present any
high-impact reframe to the user the way the Leverage Check does, then let them decide.

## Phase 5: Success Criteria

### Define Measurable Outcomes

```markdown
## Success Criteria

### Functional

- [ ] [Specific testable criterion]
- [ ] [Specific testable criterion]

### Quality

- [ ] [Performance/reliability criterion]
- [ ] [User experience criterion]

### Business (if applicable)

- [Measurable business outcome]
```

Ask:

- "How will we know this is working?"
- "What would make this a success vs. just 'done'?"

## Phase 6: Capture Open Questions

### Document Unknowns

```markdown
## Open Questions

- [ ] [Question needing stakeholder input]
- [ ] [Technical uncertainty to resolve]
- [ ] [Decision to be made later]
```

Ask: "What questions do we still need to answer before or during implementation?"

## Capture Requirements

### Determine Project Name

```bash
# Get project name from git or directory
basename $(git rev-parse --show-toplevel 2>/dev/null || pwd)
```

Or ask user if unclear: "What should we call this project/feature?"

### Create Planning Directory

```bash
mkdir -p ./planning/<project>/
```

This directory is created in both modes — it holds `implementation-plan.md` and `session-state.md` regardless of
requirements source.

### File Mode: Generate requirements.md

**Only in file mode.** Write `./planning/<project>/requirements.md`:

```markdown
# [Feature Title]

## Problem Statement

[Who has this problem and what happens - from Phase 1]

## Proposed Solution

[High-level approach - from Phase 2]

## User Stories

### Core Stories

- As a [user], I want [capability] so that [benefit]

### Supporting Stories

- As a [user], I want [capability] so that [benefit]

## Key Requirements

### Must Have

- [Essential requirement]

### Nice to Have

- [Optional requirement]

### Out of Scope

- [Explicitly excluded]

## Open Questions

- [ ] [Unresolved items needing input]

## Dependencies

_Per-item dependency metadata (omit this section for a single-item refinement). One entry
per produced item — story or sub-issue. See Phase 3.5._

- **[Item name or key]**
  - blocks: [items this one blocks, or none]
  - blocked_by: [items that must finish first, or none]
  - parallelizable_with: [peer items safe to run concurrently, or none]

## Success Criteria

- [ ] [Measurable outcome]

## Related

- Issue: [ISSUE-ID or "Not created"]
- Implementation Plan: [Link when created]

---
Created: [timestamp]
Status: Draft
```

### PM Mode: Write Requirements to PM Issue

**Only in PM mode.** Write the refined requirements directly to the PM issue. No `requirements.md` is created.

If refining an existing issue, update it. If starting from scratch, create a new issue first.

For issue creation and update MCP calls and field mappings, reference @workflow (`planning/pm-integration.md`).

Write the structured description to the issue using the description structure defined in @workflow
(`planning/pm-integration.md` — Issue Update section).

**Dependency metadata (PM mode).** When the refinement produced multiple items, record the
Phase 3.5 dependencies as native issue relations — set "blocks" / "blocked by" links between
the issues where the PM tool supports them (Linear and Jira both do). Capture
`parallelizable_with` as an issue note or label, since most PM tools have no native field for
it.

## PM Tool Integration (file mode only)

**Skip this section entirely in PM mode** — the issue was already created/updated above.

In file mode, optionally offer issue creation after saving `requirements.md`:

### Detect PM Configuration

```bash
# Check for PM tool configuration
cat .claude/settings.json 2>/dev/null | grep -A10 project_management

# Check for available MCP tools
# Linear: mcp__linear__createIssue
# Jira: mcp__jira__createIssue
```

### Offer Issue Creation

If PM tool is configured or available:

```markdown
## Create Tracking Issue?

Requirements are ready. Would you like to create a tracking issue?

1. **Yes - Create issue** in [Linear/Jira]
2. **No - Just save requirements** (create issue later)
3. **Link existing issue** - provide issue ID
```

### Linear Issue Creation

If Linear MCP available:

```bash
mcp__linear__createIssue({
  title: "[Feature Title]",
  description: "[Problem statement + proposed solution summary]",
  teamId: "[from config or ask]"
})
```

Update requirements.md with issue ID:

```markdown
## Related

- Issue: LIN-[new-id]
```

### Jira Issue Creation

If Jira MCP available:

```bash
mcp__jira__createIssue({
  projectKey: "[from config or ask]",
  summary: "[Feature Title]",
  description: "[Problem statement + proposed solution summary]",
  issueType: "Story"
})
```

Update requirements.md with issue key:

```markdown
## Related

- Issue: [PROJ-new-id]
```

### Manual Tracking

If no PM integration:

```markdown
## Manual Tracking

Requirements saved to: `./planning/[project]/requirements.md`

To track this work:

1. Create an issue in your tracking system
2. Update the "Related" section with the issue ID
3. Run `/workflow:plan` when ready to create implementation plan
```

## Completion

Present summary to user based on mode:

### File Mode Completion

```markdown
## Requirements Complete

Created: `./planning/[project]/requirements.md`
Issue: [ISSUE-ID or "Not created"]
Status: Ready for Planning

### Summary

**Problem**: [one-line problem statement]
**Solution**: [one-line approach]
**Core Stories**: [count]
**Must-Have Requirements**: [count]

### What's Next?

1. **Create implementation plan** - `/workflow:plan ./planning/[project]/requirements.md`
2. **Review requirements** - Open requirements.md for review
3. **Refine further** - `/workflow:refine ./planning/[project]/requirements.md`
4. **Share for feedback** - Send requirements to stakeholders
```

### PM Mode Completion

```markdown
## Requirements Complete

Issue: [ISSUE-ID] (updated with refined requirements)
Planning directory: `./planning/[project]/` (ready for implementation plan)
Status: Ready for Planning

### Summary

**Problem**: [one-line problem statement]
**Solution**: [one-line approach]
**Core Stories**: [count]
**Must-Have Requirements**: [count]

### What's Next?

1. **Create implementation plan** - `/workflow:plan [ISSUE-ID]`
2. **View requirements** - Check [ISSUE-ID] in [Linear/Jira]
3. **Refine further** - `/workflow:refine [ISSUE-ID]`
4. **Share for feedback** - Share issue with stakeholders
```

## Key Principles

### Discovery Over Documentation

- Focus on understanding the problem
- Documentation captures understanding, not drives it
- Questions are more valuable than assumptions

### Conversation Is the Tool

- Guide through questions, not templates
- Adapt based on user responses
- Skip phases that aren't relevant

### Minimum Viable Requirements

- Capture enough to start planning
- Don't over-specify details that will emerge during implementation
- Mark unknowns as open questions

### Separate Concerns

- Requirements define "what" and "why"
- Planning (next step) defines "how"
- This command focuses on requirements only
