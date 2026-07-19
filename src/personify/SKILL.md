---
name: personify
description: Agent personality, voice guidance, and communication facts. Two-layer storage — user-space ~/.agent-tools/personify.md (shared defaults) plus optional project .agent-tools/personify.md (local override/delta). Enforces size limits, proactive maintenance, and AGENTS.md imports. Invocable as /personify for interactive init or collaborative edit+cleanup.
user-invocable: true
---

# Personify

`/personify` defines and maintains a durable "agent personality" — how the agent communicates and behaves interpersonally: tone, voice, style preferences, and key interaction facts.

**Only communication and interpersonal content belongs here.** No technical instructions, codebase memories, or project facts (those go in charter, conventions, or harness instruction files).

## Two-layer model

| Layer | Path | Role |
|-------|------|------|
| **User** (shared defaults) | `~/.agent-tools/personify.md` | Cross-project voice and behavior. Applies to every project. |
| **Project** (local override) | `.agent-tools/personify.md` | Project/audience/domain delta. Wins on conflict. |

Same idea as skill defaults + project `conventions.md`, but with an explicit user layer: **user is the base; project is the override.**

### Merge semantics (cascade)

When both layers exist, agents build an **effective profile** as follows:

1. Start from the **user** profile (all sections).
2. Overlay the **project** profile:
   - Project bullets in the same section **add** to the effective set.
   - A project bullet that starts with `OVERRIDE` (or is clearly a direct contradiction of a user rule on the same topic) **replaces** that user rule for this project.
   - Project **Persistent Facts** are additive unless the project explicitly revokes one.
3. Project wins on conflict. User alone is enough when no project file exists.

**Do not duplicate** user rules into project files. Project files should be thin deltas after promotion.

### Optional section: Technical Language

Either layer may include `## Technical Language (STE-inspired principles)` — controlled-language *principles* for technical prose (active voice, short sentences, one claim per sentence, lists for multi-step). This is **not** full ASD-STE100 dictionary compliance. Link: https://www.asd-ste100.org/

## Commands in This Family

| Command | Purpose |
|---------|---------|
| `/personify` | Review/edit/maintain. Default target: project if in a project with a profile, else user. |
| `/personify user` | Init or maintain the **user-space** profile only |
| `/personify project` | Init or maintain the **project** profile only |
| `/personify promote` | Diff project vs user; propose lifting shared rules into user-space and thinning the project file |

## When to Use This Skill

- Starting a new project or collaboration and want consistent agent voice.
- The agent is forgetting or varying tone, structure, or interpersonal facts across sessions.
- The same voice rules are repeated across projects → promote to user-space.
- A profile is approaching size limits or needs quality pruning.
- You want a lightweight, bounded profile focused on *how the agent talks and behaves with humans*.

## Profile Format

Use a single markdown file per layer with these sections. Keep content strictly to personality, voice, and communication style.

Recommended header:

```markdown
# Agent Personify Profile (user-space)
#   — or — (project override)

> Layer: user | Size: 420 / 600 tokens (70%) | Last maintained: 2026-07-18
>
> Shared defaults for all projects. Project `.agent-tools/personify.md` is a local override.
```

(Project header should say `Layer: project` and note that it is a delta on user-space.)

### Sections

```markdown
## Personality & Behaviors

[Traits and consistent behaviors.]

## Voice Guidance (speaking and writing)

[Speaking and writing style; anti-patterns; examples.]

## Technical Language (STE-inspired principles)   # optional

[Principles only — not full STE dictionary compliance.]

## Persistent Facts

[Interpersonal/communication facts only.]

**Scope note:** How the agent presents itself and communicates — not technical decisions or project history.
```

For a commented starting example, see [references/example.md](references/example.md). Remove `<!-- -->` comments before live use.

## Size Limits and Maintenance

Token limits force prioritization (inspired by bounded-memory designs like Hermes). Approximate tokens as ~4 characters per token, or use a platform tokenizer when available.

| Scope | Warn | Strong | Hard max |
|-------|------|--------|----------|
| **User** layer | 400 | 500 | **600** |
| **Project** layer | 400 | 500 | **600** |
| **Combined** (user + project loaded) | 900 | 1050 | **1200** |

Combined hard max equals two full layers so a rich project house-voice delta can coexist with a full user base; prefer thin deltas so combined stays near the warn band. Legacy single-file projects without user-space may still use a per-file 1,200 cap until promoted.

On every `/personify` run:

- Show live usage for the target layer (and combined if both exist).
- In a project, verify that its `AGENTS.md` explicitly imports every existing profile layer.
- Enter maintenance mode at thresholds or on request: flag duplicates, verbose phrasing, content that belongs in the other layer, and out-of-scope technical drift.
- Propose concrete before/after changes; user approves.
- Goal: dense, current profiles under hard max without losing important voice or facts.

High-quality entries are durable, non-redundant, directly influence voice/behavior, and high-signal.

## Behavior

Parse arguments: empty | `user` | `project` | `promote` (plus free-form context).

### Target resolution

- `user` → `~/.agent-tools/personify.md` only.
- `project` → `.agent-tools/personify.md` in the current project root only.
- empty → if cwd is a project with (or needing) a project profile, prefer project; also surface user size if present. If no project context, target user.
- `promote` → see Promote mode below.

### AGENTS.md import verification

On **every** `/personify` run inside a project, inspect the project-root `AGENTS.md`. A profile does
not reliably reach future session context merely because its file exists.

1. If `~/.agent-tools/personify.md` exists, require `@~/.agent-tools/personify.md` in the managed
   personify block.
2. If `.agent-tools/personify.md` exists, also require `@.agent-tools/personify.md` in that block.
3. Remove only stale personify imports for profile layers that no longer exist. Never alter unrelated
   `AGENTS.md` content.
4. If the block is missing or stale, show the proposed managed-block diff and ask for approval to
   repair it. Do not report setup as complete if the repair is declined; state that future sessions
   may not load the profile.
5. If the project has no `AGENTS.md`, offer to create one containing the managed block.

Use this user-only form when no project overlay exists:

```markdown
<!-- agent-tools:personify-link begin -->
## Agent Personify Profile

Load the user-space profile for agent personality, voice, and interpersonal style:

@~/.agent-tools/personify.md
<!-- agent-tools:personify-link end -->
```

When both layers exist, use the combined form under **Setting Up → Project**.

### No profile yet (target path missing)

1. Create directory and file if needed.
2. Interactive session: targeted questions for the three main sections (plus optional Technical Language).
3. For **project** init when user-space already exists: start from an empty delta template and only capture *overrides* and project-specific facts — do not copy the whole user file.
4. Present draft with size header; iterate until approved.
5. Write the file.
6. Run the `AGENTS.md` import verification when in a project.
7. Summarize usage and next steps.

### Profile exists

1. Read target file; compute size. If both layers exist, also report combined.
2. Display full profile (or section-by-section) plus usage meters.
3. Propose maintenance near limits, on redundancy, or on request.
4. Menu: `tweak personality / voice / facts / technical language / review & maintain / see raw / promote candidates / done`
5. Apply only approved changes. Re-check size.
6. Run the `AGENTS.md` import verification when in a project.

### Promote mode (`/personify promote`)

1. Read user and project profiles (error if project missing).
2. Diff: list project bullets that also appear (semantically) in other projects or that are clearly cross-project defaults.
3. Propose a batch: move to user, remove from project (or mark OVERRIDE if project needs a variant).
4. Apply only after user approval. Re-check both sizes.

Always non-destructive and collaborative. Show diffs / before-after. User retains final say.

## Setting Up

### User-space (once per machine)

```text
/personify user
```

Creates `~/.agent-tools/personify.md` if missing. There is no single global `AGENTS.md` change, but
each project must explicitly import this profile so its harness loads it in future sessions.

### Project

```text
/personify project
```

Creates `.agent-tools/personify.md` as a **delta** when user-space exists.

When both profile layers exist, add this managed block to project `AGENTS.md` (after charter if
present):

```markdown
<!-- agent-tools:personify-link begin -->
## Agent Personify Profile

Load the user-space profile, then the project override:

@~/.agent-tools/personify.md
@.agent-tools/personify.md
<!-- agent-tools:personify-link end -->
```

## How Agents Should Apply the Profile

At the start of a work session (or before substantial replies):

1. **Read user-space** if it exists: `~/.agent-tools/personify.md` (expand `~` to the user's home).
2. **Read project** if linked or present: `.agent-tools/personify.md`.
3. **Merge** per cascade rules above (project wins on conflict).
4. Let personality and voice shape tone, structure, length, and examples.
5. Apply Technical Language principles to technical prose, plans, procedures, and PM text — not as a rigid dictionary checker.
6. Use Persistent Facts when relevant.
7. Stay in scope: no technical/project content that belongs elsewhere.
8. If either layer or combined usage approaches warn thresholds, surface `/personify` maintenance rather than letting low-signal content accumulate.

Examples:

- User asks for a plan → structure from effective profile (recommendation-first, tight bullets).
- Writing a commit or comment → match voice; STE-inspired clarity for procedural text.
- Project has Daybreak/Jira house voice → project OVERRIDE wins for PM-facing prose.

## Related Skills

- **workflow** — Personify complements session continuity and `planning/conventions.md` (process; not voice).
- **swarm** — Use after `/swarm:setup` for communication preferences.
- **skills** — The personify skill itself can be evolved like other skills.

## References

Bounded multi-layer memory (size limits + maintenance), narrowly scoped to agent ↔ human interaction. Not a replacement for technical docs, ADRs, or harness ops instructions.

See [references/example.md](references/example.md) for a commented example. See Hermes (SOUL + bounded MEMORY/USER), Letta core blocks, and memory-primitives patterns for design rationale on limits and collaborative upkeep.

STE context: ASD-STE100 Simplified Technical English (https://www.asd-ste100.org/) — use as *principle inspiration* only inside personify, not full standard enforcement.
