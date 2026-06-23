---
name: personify
description: Project-specific agent personality, voice guidance, and communication facts. Stores a single .agent-tools/personify.md (personality traits & behaviors, speaking/writing voice, persistent interpersonal facts only). Invocable as /personify for interactive init or edit. Agents load the data file directly via AGENTS.md.
user-invocable: true
---

# Personify

`/personify` lets you define and maintain a durable "agent personality" for a project. It steers how the agent communicates and behaves inter-personally — tone, voice, style preferences, and key facts about how to interact with the team/user.

**Only communication and interpersonal content belongs here.** No technical instructions, codebase memories, or project facts (those go in charter or other docs).

The profile lives at `.agent-tools/personify.md` (single file, directly under `.agent-tools/`). Agents load it directly via an AGENTS.md block.

## Commands in This Family

| Command | Purpose |
|---------|---------|
| `/personify` | Initialize (if missing) or review/edit the project personify profile through guided conversation |

## When to Use This Skill

- Starting a new project or collaboration and want consistent agent voice/persona from the start.
- The agent is forgetting or varying tone, structure preferences, or key interpersonal facts across sessions.
- You want a lightweight, persistent profile focused purely on *how the agent should talk and behave with humans on this project*.

## Profile Format (.agent-tools/personify.md)

Use a single markdown file with these clearly labelled sections. Keep content strictly to personality, voice, and communication style.

```markdown
# Agent Personify Profile

## Personality & Behaviors

[Traits and consistent behaviors the agent should exhibit. E.g. "Be direct and concise. Use numbered steps for plans. Celebrate small wins with the user."]

## Voice Guidance (speaking and writing)

[Speaking style: "Warm but professional, use 'we' when appropriate."
Writing style: "Short paragraphs. Bullet points for lists. Avoid jargon unless the user uses it first. Example: Instead of 'leverage synergies' say 'work together on this'."]

## Persistent Facts

[Only interpersonal/communication facts. E.g. "User prefers updates in Linear comments rather than long chat threads." "Team uses humor in technical discussions — light sarcasm is welcome." "Stakeholder X likes visual diagrams in every plan."]

**Scope note:** This file is *only* for how the agent should present itself and communicate. Do not include technical decisions, code patterns, requirements, or project history.
```

## Behavior

Parse arguments (usually empty or context).

### No profile yet (` .agent-tools/personify.md` missing)

1. Create the directory and file if needed (`.agent-tools/personify.md`).
2. Start an interactive session: ask targeted questions to build the three sections.
3. Present a draft, iterate with the user until they approve.
4. Write the file.
5. Offer to also add the AGENTS.md reference block (see below).
6. Summarize: "Profile created. Next time you run /personify I'll show the current version and let you tweak it."

### Profile exists

1. Read `.agent-tools/personify.md`.
2. Show a concise summary (e.g. "Current persona: Direct, concise, uses numbered lists. Voice: professional but approachable. Key facts: prefers Linear comments.").
3. Ask: "What would you like to do? (tweak personality / voice / facts / see full file / done)"
4. If tweak: enter collaborative edit mode — propose changes, get feedback, rewrite sections.
5. Save updates.
6. Remind about AGENTS.md if not present.

Always keep the interaction non-destructive and collaborative. Use the existing profile as ground truth.

## Setting Up in a Project

Run `/personify` in your project root.

The skill will create `.agent-tools/personify.md` if missing and guide you.

To make agents load it automatically, add this block to your project's `AGENTS.md` (after the charter block):

```markdown
## Agent Personify Profile

This project uses a personify profile for consistent agent personality, voice, and interpersonal style.

@.agent-tools/personify.md
```

(Use the same marker pattern as the charter block if you want future automation to find/refresh it.)

## How Agents Should Apply the Profile

When `@.agent-tools/personify.md` is loaded:

- Read the three sections at the start of any work session or before responding to user.
- Let the personality traits and voice guidance shape your tone, sentence length, structure, and examples.
- Reference the persistent facts when they are relevant to the current conversation or task.
- Never violate the scope: stay out of technical/project content that belongs elsewhere.

Example application:
- User asks for a plan → Use the structure preference from the profile (numbered steps, etc.).
- Writing a commit message or comment → Match the voice guidance.
- Interacting over multiple messages → Keep the personality consistent.

## Related Skills

- **workflow** — Personify complements session continuity and conventions.
- **swarm** — Use after `/swarm:setup` to add communication preferences.
- **skills** — The personify skill itself can be evolved like other skills.

## References

The profile is project memory, similar to charter but narrowly scoped to agent <-> human interaction. It is not a replacement for technical docs or ADRs.