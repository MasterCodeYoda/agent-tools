---
name: personify
description: Project-specific agent personality, voice guidance, and communication facts. Stores a single bounded .agent-tools/personify.md (personality traits & behaviors, speaking/writing voice, persistent interpersonal facts only). Enforces size limits and proactive maintenance on subsequent runs. Invocable as /personify for interactive init or collaborative edit+cleanup. Agents load the data file directly via AGENTS.md.
user-invocable: true
---

# Personify

`/personify` lets you define and maintain a durable "agent personality" for a project. It steers how the agent communicates and behaves inter-personally — tone, voice, style preferences, and key facts about how to interact with the team/user.

**Only communication and interpersonal content belongs here.** No technical instructions, codebase memories, or project facts (those go in charter or other docs).

The profile lives at `.agent-tools/personify.md` (single bounded file under `.agent-tools/`). It uses explicit size limits and quality maintenance to stay high-signal and avoid context bloat. Agents load it directly via an AGENTS.md block.

The agent and user work together: the agent proposes cleanups, merges, and refinements based on size/quality signals; the user directs priorities and final decisions.

## Commands in This Family

| Command | Purpose |
|---------|---------|
| `/personify` | Initialize (if missing) or review/edit + maintain (display current memory, size, propose cleanup) the project personify profile through guided collaboration |

## When to Use This Skill

- Starting a new project or collaboration and want consistent agent voice/persona from the start.
- The agent is forgetting or varying tone, structure preferences, or key interpersonal facts across sessions.
- The profile is approaching size limits, has accumulated redundancy, or needs quality pruning to stay high-signal.
- You want a lightweight, bounded, persistent profile focused purely on *how the agent should talk and behave with humans on this project* (with built-in maintenance).

## Profile Format (.agent-tools/personify.md)

Use a single markdown file with these clearly labelled sections. Keep content strictly to personality, voice, and communication style.

**Size limits (enforced, token-based):** three escalating thresholds — see **Size Limits and
Maintenance** below for the canonical values and required actions.

This keeps the profile potent, cheap to load every session, and prevents attention dilution. The `/personify` skill surfaces usage (in tokens) on every run and guides consolidation when approaching thresholds. (Approximate tokens: ~4 characters per token, or use platform tokenizer if available.)

Recommended top-of-file header for visibility:

```markdown
# Agent Personify Profile

> Size: 720 / 1,200 tokens (60%) | Last maintained: 2026-06-23
```

### Sections

```markdown
## Personality & Behaviors

[Traits and consistent behaviors the agent should exhibit. E.g. "Be direct and concise. Use numbered steps for plans. Celebrate small wins with the user."]

## Voice Guidance (speaking and writing)

[Speaking style: "Warm but professional, use 'we' when appropriate."
Writing style: "Short paragraphs. Bullet points for lists. Avoid jargon unless the user uses it first. Example: Instead of 'leverage synergies' say 'work together on this'."]

## Persistent Facts

[Only interpersonal/communication facts. E.g. "User prefers updates in Linear comments rather than long chat threads." "Team uses humor in technical discussions — light sarcasm is welcome." "Stakeholder X likes visual diagrams in every plan."]

**Scope note:** This file is *only* for how the agent should present itself and communicate. Do not include technical decisions, code patterns, requirements, or project history.
```

For a complete, maintained example that includes a reasonable starting persona (with the recommended header, good density across all three sections, and explanatory notes), see [references/example.md](references/example.md). Remove the `<!-- -->` comments before using in a real project.

## Size Limits and Maintenance

The token limits are deliberate (inspired by successful bounded-memory designs like Hermes' tiny prompt-resident files). They force prioritization of only the highest-leverage interpersonal and voice guidance.

- **800 tokens**: Start warning the user (approaching limit, consider cleanup).
- **1,000 tokens**: Stronger warning + explicit suggestions for consolidation.
- **1,200 tokens**: Forced maintenance — the skill requires review and cleanup before allowing further growth.

- The skill always shows live usage (in tokens) on profile load.
- It enters maintenance mode at the thresholds above (or on explicit request):
  - Identifies candidates for consolidation (duplicate facts, verbose phrasing, low-recency items).
  - Proposes concrete before/after changes.
  - Walks you through approval, editing, or rejection one item (or batch) at a time.
- You can always request "review & maintain" from the menu.
- Goal: keep the profile dense, current, and under the 1,200 token hard limit without losing important voice or facts.
- Agent role: surfaces signals and drafts improvements. Your role: set priorities ("this fact is critical, keep it even if verbose").

This pairs user direction with agent assistance — never agent-only or user-only edits. High-quality entries are those that are durable (cross-session), non-redundant, directly influence voice/behavior, and high-signal.

## Behavior

Parse arguments (usually empty or context).

### No profile yet (`.agent-tools/personify.md` missing)

1. Create the directory and file if needed (`.agent-tools/personify.md`).
2. Start an interactive session: ask targeted questions to build the three sections.
3. Present a draft (including initial size/usage header), iterate with the user until they approve.
4. Write the file with the approved content + usage header.
5. Offer to also add the AGENTS.md reference block (see below).
6. Summarize: "Profile created (under limits). Next time you run /personify I will display the full current memory + usage in tokens, propose any cleanup or consolidation needed, and guide you through maintenance while you direct changes."

### Profile exists

1. Read `.agent-tools/personify.md` and compute current size/usage in tokens.
2. Display the full current profile (or section-by-section for readability) **plus** a clear usage meter (e.g. "Size: 920 / 1,200 tokens (77%) — strong warning, consider maintenance").
3. Propose maintenance if near the limit, if obvious redundancies are detected, or on request:
   - List specific suggestions: "These two Persistent Facts overlap on humor preference. Proposed merge: '...'. Remove one? Rephrase for density?"
   - "Voice section has grown wordy. Suggested tightened version: [diff]."
   - Offer "Full review & cleanup" pass.
4. Present menu: "tweak personality / voice / facts / review & maintain (cleanup/consolidate) / see raw file / done"
5. If tweak or maintain: enter collaborative mode. The agent proposes targeted changes, merges, or prunes based on size, signal strength, and scope. You review, edit, approve, or direct priorities (e.g. "keep the sarcasm example, drop the diagram one").
6. Apply only approved changes. Re-check size and show updated usage.
7. Remind about AGENTS.md if not present.

Always keep the interaction non-destructive and collaborative. The agent and user work together: the agent surfaces the current memory, flags bloat, and proposes high-quality refinements; you retain final say on what is kept or changed. Use the existing profile as ground truth. Changes are always shown as diffs or before/after for review.

## Setting Up in a Project

Run `/personify` in your project root.

The skill will create `.agent-tools/personify.md` (with token-based size tracking) if missing and guide you. On every future run it will show the live memory + usage (in tokens) and drive any needed maintenance.

To make agents load it automatically, add this block to your project's `AGENTS.md` (after the Project Charter section if present):

```markdown
## Agent Personify Profile

This project uses a personify profile for consistent agent personality, voice, and interpersonal style.

@.agent-tools/personify.md
```

(Use the same marker pattern as the charter block if you want future automation to find/refresh it.)

## How Agents Should Apply the Profile

When `@.agent-tools/personify.md` is loaded:

- Read the three sections (and any size/maintenance header) at the start of any work session or before responding to user.
- Let the personality traits and voice guidance shape your tone, sentence length, structure, and examples. Stay concise to respect the bounded size.
- Reference the persistent facts when they are relevant to the current conversation or task.
- Never violate the scope: stay out of technical/project content that belongs elsewhere.
- If the profile approaches the 800-token warning threshold (or higher), surface the need for `/personify` maintenance rather than letting low-signal content accumulate.

Example application:
- User asks for a plan → Use the structure preference from the profile (numbered steps, etc.).
- Writing a commit message or comment → Match the voice guidance.
- Interacting over multiple messages → Keep the personality consistent.

## Related Skills

- **workflow** — Personify complements session continuity and conventions.
- **swarm** — Use after `/swarm:setup` to add communication preferences.
- **skills** — The personify skill itself can be evolved like other skills.

## References

The profile is bounded project memory (with the token limits from Size Limits and Maintenance plus proactive maintenance), similar to charter but narrowly scoped to agent <-> human interaction. It is not a replacement for technical docs or ADRs.

See [references/example.md](references/example.md) for a fully commented example of a reasonable starting persona (remove the `<!-- -->` comments for live use). We keep this example updated with broadly applicable positions.

See the research on systems like Hermes (SOUL + bounded MEMORY/USER with forced consolidation), Letta core blocks, and memory-primitives.md patterns for the design rationale around limits, quality, and collaborative upkeep.