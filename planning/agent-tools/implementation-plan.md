---
project: agent-tools
work_item: null
blocks: []
blocked_by: []
parallelizable_with: []
---

# Implementation Plan: Personify Skill

## Approach

This is a cross-cutting foundation addition to the agent-tools skill corpus. We are introducing a new skill `/personify` that allows projects to define a persistent "agent personality and communication profile" stored as `.agent-tools/personify.md`, with the `/personify` command providing interactive management, and clear guidance for agents to load and apply it via AGENTS.md.

The implementation is primarily the creation of a comprehensive `src/personify/SKILL.md` that serves as both the skill definition and the detailed spec for the profile format and behavior.

Supporting updates are limited to the main README (skills table and new command section) so the feature is discoverable. The publishing pipeline and setup will handle the new skill automatically.

We follow deliverable-partition mode per the requirements. All tasks are required. Implementation order respects the documented dependencies (profile convention first).

## Breakdown

### Mode

Deliverable-partition — sub-case: Cross-cutting / foundation (new persistent mechanism in the `.agent-tools` umbrella that affects agent behavior across all workflows and swarms).

### Overview

This epic produces the `/personify` capability for project-specific agent personality and communication guidance. It delivers four distinct artifacts:
- The skill definition (src/personify/SKILL.md).
- The profile storage convention (.agent-tools/personify.md format and scope).
- The management interface behavior (the /personify command's auto-orienting flow).
- The context loading integration (AGENTS.md block and guidance).

### Why deliverable-partition (not vertical slice)

This epic produces several distinct, reusable artifacts (the skill definition, the data convention, the management surface, and the loading integration). Each needs to be delivered comprehensively with its own Definition of Done. Vertical slicing would risk partial profiles or incomplete loading that don't deliver the "steers behavior" outcome until everything lands.

### Parent Acceptance Criteria

- [ ] AC1 — There is a user-invocable `/personify` skill published in the canonical agent-tools corpus.
- [ ] AC2 — Projects can create and store a personify profile as `.agent-tools/personify.md` (single file) that persists across sessions.
- [ ] AC3 — The profile contains *only* content related to agent personality and communication style (personality traits & behaviors, speaking/writing voice guidance, and persistent facts that steer interpersonal/communication behavior). It contains no technical instructions or project memories.
- [ ] AC4 — Invoking `/personify` allows users to initialize (if missing) or inspect/tweak an existing profile through guided interaction.
- [ ] AC5 — Agents working in the project automatically have access to the personify profile via a dedicated block in AGENTS.md (referencing `@.agent-tools/personify.md` directly).
- [ ] AC6 — The implementation follows existing skill conventions (frontmatter, publishing) and .agent-tools umbrella rules (non-destructive, add-don't-remove gitignore, documented). The skill itself requires no agent-specific markup for v1.

### AC Traceability Matrix

| Parent AC | Owning sub-issue                          | Verified at       |
|-----------|-------------------------------------------|-------------------|
| AC1       | Sub-issue 1 (Personify Skill Definition)  | Sub-issue 1 close |
| AC2       | Sub-issue 2 (Profile Storage Convention)  | Sub-issue 2 close |
| AC3       | Sub-issue 2 (Profile Storage Convention)  | Sub-issue 2 close |
| AC4       | Sub-issue 3 (Management Interface)        | Sub-issue 3 close |
| AC5       | Sub-issue 4 (Context Loading Integration) | Sub-issue 4 close |
| AC6       | Sub-issue 1 (Personify Skill Definition)  | Sub-issue 1 close |

### Sub-issue Breakdown

#### Sub-issue 1: Personify Skill Definition

**Inherits (verbatim from parent, verified at this sub-issue's close):**

- [ ] AC1 — There is a user-invocable `/personify` skill published in the canonical agent-tools corpus.
- [ ] AC6 — The implementation follows existing skill conventions (frontmatter, publishing) and .agent-tools umbrella rules (non-destructive, add-don't-remove gitignore, documented). The skill itself requires no agent-specific markup for v1.

**Sub-issue-specific tasks:**

- [ ] Create the directory `src/personify/`.
- [ ] Write the YAML frontmatter for `src/personify/SKILL.md` (name: personify, description matching the refined purpose, user-invocable: true).
- [ ] Write the main `# Personify` introduction and purpose, matching the refined proposed solution exactly.
- [ ] Write the "Commands in This Family" table (single entry for `/personify`).
- [ ] Write the "When to Use This Skill" section.
- [ ] Write the detailed profile structure section, including the three clearly labelled sections, examples, and the strict scope rules (no technical/project facts) from AC3.
- [ ] Write the full "Behavior" section describing the exact auto-orienting logic for the `/personify` command (initialize + interactive discussion if file missing; brief summary + ask for tweaks if present).
- [ ] Write the "Setting Up in a Project" / loading section, including the exact recommended AGENTS.md block with marker.
- [ ] Write the "How Agents Should Apply the Profile" guidance section.
- [ ] Write the "Related Skills" section, cross-referencing workflow, swarm, etc.
- [ ] Proofread the entire file for consistency with peer skills (e.g., swarm, product).
- [ ] Verify and confirm zero agent-specific markup is present.
- [ ] Ensure the document references the exact profile path `.agent-tools/personify.md`.

**Dependencies:**

- Blocked by: Sub-issue 2 (needs to know the profile format it will describe)

**Definition of Done:**

- All inherited parent ACs verified
- Skill file published cleanly via the existing publisher
- Skill appears in `dist/` for supported agents and in README tables

#### Sub-issue 2: Profile Storage Convention

**Inherits (verbatim from parent, verified at this sub-issue's close):**

- [ ] AC2 — Projects can create and store a personify profile as `.agent-tools/personify.md` (single file) that persists across sessions.
- [ ] AC3 — The profile contains *only* content related to agent personality and communication style (personality traits & behaviors, speaking/writing voice guidance, and persistent facts that steer interpersonal/communication behavior). It contains no technical instructions or project memories.

**Sub-issue-specific tasks:**

- [ ] Finalize and document the file location as the single `.agent-tools/personify.md` (directly under `.agent-tools/`).
- [ ] Define the exact content format with the three labelled markdown sections:
  - `## Personality & Behaviors`
  - `## Voice Guidance (speaking and writing)`
  - `## Persistent Facts` (strictly limited to interpersonal/communication style)
- [ ] Create and include a complete seed/template profile example inside the skill documentation.
- [ ] Write explicit "scope boundaries" text: what does *not* belong (technical instructions, project memories, etc.).
- [ ] Document contrast with charter content.
- [ ] Specify any `.agent-tools/.gitignore` changes (add-don't-remove policy; likely none for this file).

**Dependencies:**

- Blocked by: none (foundational data model)

**Definition of Done:**

- All inherited parent ACs verified
- Clear, minimal single-file spec that is easy for humans to edit and agents to consume
- Example/seed profile included
- Gitignore updated correctly if required

#### Sub-issue 3: Management Interface

**Inherits (verbatim from parent, verified at this sub-issue's close):**

- [ ] AC4 — Invoking `/personify` allows users to initialize (if missing) or inspect/tweak an existing profile through guided interaction.

**Sub-issue-specific tasks:**

- [ ] In the `src/personify/SKILL.md`, fully specify the "User Input" and "Behavior" sections for the single `/personify` command (no sub-commands).
- [ ] Detail the "file does not exist" flow: initialize the file and walk the user through an interactive, collaborative discussion to establish personality/voice, then write the file.
- [ ] Detail the "file exists" flow: present a brief summary of the current agent personality, then ask what the user wants to do (e.g. tweak traits/behaviors/voice) and drop into a collaborative refinement session.
- [ ] Include concrete example prompts and conversation flows.
- [ ] Emphasize that the interaction must be non-destructive and evidence-grounded.
- [ ] Document the full auto-orienting behavior clearly.

**Dependencies:**

- Blocked by: Sub-issue 2 (needs to know the file format it will manage)
- Blocked by: Sub-issue 1 (the skill definition describes the behavior)

**Definition of Done:**

- All inherited parent ACs verified
- The single `/personify` command is practical, follows the auto-orienting pattern described, and works for host agents
- Behavior is fully documented in the skill with examples

#### Sub-issue 4: Context Loading Integration

**Inherits (verbatim from parent, verified at this sub-issue's close):**

- [ ] AC5 — Agents working in the project automatically have access to the personify profile via a dedicated block in AGENTS.md (referencing `@.agent-tools/personify.md` directly).

**Sub-issue-specific tasks:**

- [ ] In the SKILL.md, write the "Setting Up in a Project" section with the exact marker-bounded AGENTS.md block text (positioned after the charter section; direct `@.agent-tools/personify.md` reference).
- [ ] Explicitly state that agents load the personify data *directly* from the file (the skill is user-invoked only and is not referenced from AGENTS.md for loading).
- [ ] Add light integration notes (e.g., "After running `/swarm:init` or `/workflow:setup`, you may want to invoke `/personify` to establish communication preferences").
- [ ] Update `README.md`:
  - Add a row for **personify** in the main "Skills — Reusable Knowledge Modules" table.
  - Add a "Personify Commands" section under Commands (showing `/personify`).
  - Update the project structure diagram under `src/` to list `personify/`.
- [ ] Ensure the skill itself documents the loading mechanism for users and agents.

**Dependencies:**

- Blocked by: Sub-issue 1 and Sub-issue 2
- Parallelizable with: Sub-issue 3

**Definition of Done:**

- All inherited parent ACs verified
- Profile is reliably available via the AGENTS.md block when an agent loads the project
- Clear instructions in both the skill and the README
- README updates are complete and accurate

### Implementation Order

1. Sub-issue 2 (Profile Storage Convention) — define the exact format, scope, and example first (foundational for everything else).
2. Sub-issue 1 (Personify Skill Definition) — create the core `src/personify/SKILL.md` incorporating the format from #2 and high-level structure.
3. Sub-issue 3 (Management Interface) — expand the detailed auto-orienting behavior, prompts, and examples inside the SKILL.md.
4. Sub-issue 4 (Context Loading Integration) — add the loading documentation to the skill and perform the README updates (can have some overlap with prior steps for doc authoring).

### Technical Decisions

- Profile format: single `.agent-tools/personify.md` (flat under `.agent-tools/`, pure markdown with ## sections). No YAML frontmatter in v1 to keep it human-first and simple.
- Command surface: single `/personify` (no colon sub-commands for management; all behavior is inside the one invocation with auto-orienting).
- Loading mechanism: direct `@.agent-tools/personify.md` reference in a dedicated marker-bounded block in AGENTS.md (after the charter block). The skill file itself is *not* loaded for agent context.
- No agent-specific markup in v1 (the skill is fully portable).
- The "implementation" of the capability lives in the documentation of the SKILL.md (agents and users follow the described behavior).
- The skill will be `publish-target: user-profile` (default).
- Dogfooding in this repo (running the described `/personify` here) is nice-to-have and can happen after this epic.
- The AGENTS.md block will follow the same marker pattern as the charter block for potential future management.

### Testing Strategy

- Author `src/personify/SKILL.md` following the exact structure, tone, and conventions of peer skills (e.g. `swarm/SKILL.md`, `product/SKILL.md`).
- Cross-review the completed skill against the full requirements (AC traceability, strict scope, exact flows, examples).
- Simulate the `/personify` flows using guided conversation (e.g. AskUserQuestion) to validate the interactive logic.
- After running `setup.sh`, verify the skill appears cleanly in `dist/<agent>/skills/personify/SKILL.md` for all agents.
- Review README updates for accuracy and completeness.
- Apply relevant practices from `@test-strategy` (clarity, no implementation leakage, behavioral descriptions).

### Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Users accidentally put technical/project facts into the profile | Medium | Medium | Extremely explicit scope language, "what does not belong" section, and examples in the skill |
| Agents fail to reliably load/apply the profile | Low | High | Direct `@` reference + clear "How Agents Should Apply" section + consistent AGENTS.md marker |
| Skill documentation is inconsistent with corpus style | Low | Low | Base directly on existing high-quality skills (swarm, product); peer review step |
| Over-coupling to swarm/workflow init | Low | Low | Only light/optional mentions (per refined requirements) |
| Profile maintenance is neglected | Medium | Low | Make the `/personify` command self-documenting and low-friction with the auto-orienting flow |

### Gap-prevention check (run before parent epic closes)

- [ ] Every parent AC appears in exactly one sub-issue's "Inherits" block.
- [ ] No sub-issue has paraphrased ACs; each is verbatim from the parent.
- [ ] Every closed sub-issue verified its inherited ACs.
- [ ] Any deferred AC has a tracking issue + explicit approval; otherwise the parent does not close.

### Out of Scope

- Automatically generating a full profile from chat history without explicit user approval.
- Replacing or duplicating the charter (personify is specifically about *agent* behavior and communication).
- Global (non-project) personify profiles.
- Deep decision-making rules beyond communication and interpersonal behavior.
- "Apply personify voice" rewrite helpers (nice-to-have).
- Per-agent or per-user overrides within a project (nice-to-have).
- Heavy integration or automatic seeding in `/swarm:init` or `/workflow:setup`.

## Next Steps (after plan approval)

1. User explicitly approves.
2. Documents are saved and branch created.
3. Proceed to `/workflow:execute ./planning/agent-tools/` (or `/workflow:execute --worktree` if desired for isolation).
