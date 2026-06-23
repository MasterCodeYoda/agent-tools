# Personify Skill

## Problem Statement

Agents currently have no project-scoped, persistent, and easily-maintainable way to encode "how I should behave and communicate on this project." The result is generic, drifting, or repeatedly re-explained interpersonal style (tone, voice, structure preferences, humor level, reference habits) and loss of important persistent facts (user preferences, team norms, stakeholder context). Teams and solo developers using agents across sessions and projects want the agent to "know how to be" with them on a specific codebase or collaboration — without having to paste the same instructions every new chat or watch the agent forget preferences. The charter captures *what the project is*; there is a gap for *how the agent should show up and talk* on it.

## Proposed Solution

Introduce a new top-level user-invocable skill `/personify` (implemented at `src/personify/SKILL.md` in the canonical corpus). 

The profile lives as a single file at `.agent-tools/personify.md` (directly under `.agent-tools/`). This file contains only content related to agent personality and communication style (clearly labelled sections for personality traits & behaviors, speaking/writing voice guidance, and persistent facts that affect interpersonal and communication behavior). No technical instructions, project memories, or other facts belong here.

The skill is invoked directly as `/personify` (no subcommands). On invocation:
- If `.agent-tools/personify.md` does not exist, the skill initializes the file and walks the user through an interactive discussion to establish the personality/voice.
- If the file exists, the skill presents a brief summary of the current agent personality, then asks what the user wants to do (e.g. tweak traits) and drops into a collaborative refinement session.

The profile is made available to agents via a dedicated block in `AGENTS.md` (with a refreshable marker), referenced directly as `@.agent-tools/personify.md`. The skill itself (src/personify/SKILL.md) is for user-invoked management only; agents load the data file directly.

The skill provides clear guidance that agents should follow when the profile is present.

## Mode

Deliverable-partition — sub-case: Cross-cutting / foundation (new persistent mechanism in the .agent-tools umbrella that affects agent behavior across all workflows and swarms).

## Why deliverable-partition (not vertical slice)

This epic produces several distinct, reusable artifacts (the skill definition, the data convention, the management surface, and the loading integration). Each needs to be delivered comprehensively with its own Definition of Done. Vertical slicing would risk partial profiles or incomplete loading that don't deliver the "steers behavior" outcome until everything lands.

## Parent Acceptance Criteria

- [ ] AC1 — There is a user-invocable `/personify` skill published in the canonical agent-tools corpus.
- [ ] AC2 — Projects can create and store a personify profile as `.agent-tools/personify.md` (single file) that persists across sessions.
- [ ] AC3 — The profile contains *only* content related to agent personality and communication style (personality traits & behaviors, speaking/writing voice guidance, and persistent facts that steer interpersonal/communication behavior). It contains no technical instructions or project memories.
- [ ] AC4 — Invoking `/personify` allows users to initialize (if missing) or inspect/tweak an existing profile through guided interaction.
- [ ] AC5 — Agents working in the project automatically have access to the personify profile via a dedicated block in AGENTS.md (referencing `@.agent-tools/personify.md` directly).
- [ ] AC6 — The implementation follows existing skill conventions (frontmatter, publishing) and .agent-tools umbrella rules (non-destructive, add-don't-remove gitignore, documented). The skill itself requires no agent-specific markup for v1.

## AC Traceability Matrix

| Parent AC | Owning sub-issue                          | Verified at       |
|-----------|-------------------------------------------|-------------------|
| AC1       | Sub-issue 1 (Personify Skill Definition)  | Sub-issue 1 close |
| AC2       | Sub-issue 2 (Profile Storage Convention)  | Sub-issue 2 close |
| AC3       | Sub-issue 2 (Profile Storage Convention)  | Sub-issue 2 close |
| AC4       | Sub-issue 3 (Management Interface)        | Sub-issue 3 close |
| AC5       | Sub-issue 4 (Context Loading Integration) | Sub-issue 4 close |
| AC6       | Sub-issue 1 (Personify Skill Definition)  | Sub-issue 1 close |

## Sub-issue Breakdown

#### Sub-issue 1: Personify Skill Definition

**Inherits (verbatim from parent, verified at this sub-issue's close):**

- [ ] AC1 — There is a user-invocable `/personify` skill published in the canonical agent-tools corpus.
- [ ] AC6 — The implementation follows existing skill conventions (frontmatter, agent markup support, publishing) and .agent-tools umbrella rules (non-destructive, add-don't-remove gitignore, documented).

**Sub-issue-specific tasks:**

- [ ] Create `src/personify/SKILL.md` with appropriate frontmatter (`name: personify`, `user-invocable: true`, description).
- [ ] Document the purpose, profile categories (traits/behaviors, voice, facts), and how agents should apply the profile.
- [ ] Describe the command surface (high-level `/personify` + any sub-commands or flags).
- [ ] Include usage examples and best practices.
- [ ] Add any necessary agent:include/exclude markup for differences across hosts.
- [ ] Ensure the skill references related skills (workflow, swarm, skills meta) where appropriate.

**Dependencies:**

- Blocked by: Sub-issue 2 (needs to know the profile format it will describe)

**Definition of Done:**

- All inherited parent ACs verified
- Skill file published cleanly via the existing publisher
- Skill appears in dist/ for supported agents and in README tables

#### Sub-issue 2: Profile Storage Convention

**Inherits (verbatim from parent, verified at this sub-issue's close):**

- [ ] AC2 — Projects can create and store a personify profile as `.agent-tools/personify.md` (single file) that persists across sessions.
- [ ] AC3 — The profile contains *only* content related to agent personality and communication style (personality traits & behaviors, speaking/writing voice guidance, and persistent facts that steer interpersonal/communication behavior). It contains no technical instructions or project memories.

**Sub-issue-specific tasks:**

- [ ] Define the file as `.agent-tools/personify.md` (single markdown file directly under `.agent-tools/`).
- [ ] Define the content format with clearly labelled sections:
  - ## Personality & Behaviors
  - ## Voice Guidance (speaking and writing)
  - ## Persistent Facts (strictly limited to interpersonal/communication style)
- [ ] Create a seed/template profile.
- [ ] Document scope boundaries (what does *not* belong in personify).
- [ ] Update `.agent-tools/.gitignore` (add-don't-remove) if needed.
- [ ] Provide guidance contrasting personify with charter content.

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

- [ ] All management lives directly in the `/personify` invocation (no sub-commands such as `:init`).
- [ ] On first invocation with no `.agent-tools/personify.md`: initialize the file and walk the user through an interactive, collaborative discussion to establish personality/voice, then write the file.
- [ ] On subsequent invocations: present a brief summary of the current agent personality defined in the file, then ask what the user wants to do (e.g. tweak traits/behaviors/voice) and drop into a collaborative refinement session.
- [ ] Keep the interaction non-destructive and evidence-grounded where possible.
- [ ] Document the full auto-orienting behavior clearly in the skill.

**Dependencies:**

- Blocked by: Sub-issue 2 (needs to know the file format it will manage)
- Blocked by: Sub-issue 1 (the skill definition describes the behavior)

**Definition of Done:**

- All inherited parent ACs verified
- The single `/personify` command is practical, follows the auto-orienting pattern described, and works for host agents
- Behavior is fully documented in the skill

#### Sub-issue 4: Context Loading Integration

**Inherits (verbatim from parent, verified at this sub-issue's close):**

- [ ] AC5 — Agents working in the project automatically have access to the personify profile via a dedicated block in AGENTS.md (referencing `@.agent-tools/personify.md` directly).

**Sub-issue-specific tasks:**

- [ ] Add a dedicated, marker-bounded block in `AGENTS.md` (refreshable like the charter block) that references the data file directly: `@.agent-tools/personify.md`.
- [ ] The AGENTS.md block should appear after the charter section.
- [ ] Define that agents load the personify data *directly* from the file (the skill is user-invoked only and is not referenced from AGENTS.md for loading).
- [ ] Update the personify skill (for users) to document the expected loading behavior and how agents should apply the profile.
- [ ] Decide whether `/swarm:init` or `/workflow:setup` should offer to initialize a personify profile (light mention is fine; heavy coupling not required).
- [ ] Ensure the integration is clearly documented.

**Dependencies:**

- Blocked by: Sub-issue 1 and Sub-issue 2
- Parallelizable with: Sub-issue 3

**Definition of Done:**

- All inherited parent ACs verified
- Profile is reliably available via the AGENTS.md block when an agent loads the project
- Clear instructions in both the skill and AGENTS.md update guidance

## Key Requirements

### Must Have

- Profile is the single file `.agent-tools/personify.md` and contains *only* agent personality and communication-style content (clearly labelled sections for traits & behaviors, voice guidance, and interpersonal facts). No technical instructions or project memories.
- The single user entry point is `/personify` (no sub-commands). It auto-orients: initializes the file + guides interactively if missing; shows a brief summary + offers tweaks if present.
- Storage follows .agent-tools umbrella conventions (durable, git-friendly, add-don't-remove).
- The skill is published for claude, grok, factory, and codex with no agent-specific markup for v1.
- The profile is loaded for agents via a dedicated marker-bounded block in AGENTS.md that directly references `@.agent-tools/personify.md` (positioned after the charter block).
- Follows all existing conventions (SKILL.md frontmatter, non-destructive behavior, README updates, etc.).

### Nice to Have

- The interactive initialization flow infers some defaults from existing project artifacts (README, charter, etc.).
- Helpers inside the skill for "rewrite this draft in the project personify voice".
- Versioning or history for the personify profile.
- Per-agent or per-user overrides within a project.

### Out of Scope

- Automatically generating a full profile from chat history without explicit user approval.
- Replacing or duplicating the charter (personify is specifically about *agent* behavior and communication).
- Global (non-project) personify profiles.
- Deep decision-making rules beyond communication and interpersonal behavior.

## Dependencies

- **Sub-issue 1 (Personify Skill Definition)**
  - blocks: none
  - blocked_by: Sub-issue 2 (for accurate format description)
  - parallelizable_with: Sub-issue 4 (high-level)

- **Sub-issue 2 (Profile Storage Convention)**
  - blocks: Sub-issue 1, Sub-issue 3
  - blocked_by: none
  - parallelizable_with: none

- **Sub-issue 3 (Management Interface)**
  - blocks: none
  - blocked_by: Sub-issue 2
  - parallelizable_with: Sub-issue 4

- **Sub-issue 4 (Context Loading Integration)**
  - blocks: none
  - blocked_by: Sub-issue 1, Sub-issue 2
  - parallelizable_with: Sub-issue 3

## Success Criteria

### Functional

- [ ] A user can invoke `/personify` in a fresh project and produce a usable profile via the interactive flow.
- [ ] The profile contains guidance in all three required categories.
- [ ] An agent session that loads the project can reference and follow the personify profile without the user re-explaining preferences.

### Quality

- [ ] The skill follows the same quality and structure as peer skills (swarm, workflow, etc.).
- [ ] Profile is easy for both humans to edit and agents to consume.
- [ ] No destructive behavior on existing .agent-tools content.

### Business / Adoption

- [ ] The personify profile is adopted in the agent-tools repo itself (dogfooding).
- [ ] Documentation makes the value and usage obvious in the main README.

## Open Questions

All original open questions from the brainstorm have been resolved during this refinement pass (see decisions captured in the sections above). No new open questions were identified at this time.

If new uncertainties surface during planning or implementation, they can be added here or tracked in the implementation plan.

## Related

- Issue: Not created (file mode)
- Brainstorm: `./planning/agent-tools/brainstorm.md`
- Implementation Plan: (to be created)

---
Created: 2026-06-23
Status: Refined (open questions walked through and resolved)
