# Memory Primitives

A cross-agent reference for long-term context, rules, and memory hygiene practices.

Reference for the file types, settings, hooks, and slash commands that govern what an agent remembers across sessions. Used by `/workflow:compound` (capture) and `/workflow:maintain` (memory hygiene + yield cadence); consulted when memory feels stale, bloated, or mis-scoped.

The patterns below favor an agent platform’s documented primitives over hand-rolled alternatives. When a primitive exists, prefer it: less prose in memory files, more behavior enforced by the platform.

---

## Core Concepts

These ideas are intended to be portable across agents, even when the concrete mechanisms differ.

### Durable Rules vs Transient Context
- **Durable rules** should live in long-lived memory files that are loaded every session.
- **Transient context** (one-off decisions, temporary state) should be pruned or archived so it does not pollute future sessions.

### Attention Dilution vs Silent Truncation
Two common failure modes when memory grows too large:
- **Attention dilution**: The agent receives too much information and starts ignoring instructions.
- **Silent truncation**: The platform drops older content without warning.

### Prefer Enforcement Over Prose
Whenever possible, use platform primitives (hooks, path-scoped rules, required artifacts, etc.) rather than relying on natural-language instructions that the agent might miss.

---

## Memory Systems and Scopes

### General Model

Most agents maintain at least two broad categories of memory:
- **User-authored memory** — explicit instructions written by the user or team.
- **Agent-authored memory** — automatically captured context, summaries, or learned patterns.

These are typically scoped by visibility and sharing needs (user-wide, project-wide, local-only, etc.).

### Agent-tools levels (cross-harness)

| Level | Home | Scope |
|-------|------|--------|
| **L1 Global** | User prefs (e.g. `~/.claude/CLAUDE.md`, platform Memory) | User-wide across projects |
| **L2 Project guide** | `AGENTS.md` (often with `CLAUDE.md` → symlink) | Always-load thin project rules |
| **L3-shared** | **`.agent-tools/memory/`** (git-committed) | Project-wide agent working knowledge — portable across machines and harnesses |
| **L3-local** | Harness auto-memory (e.g. Claude project `MEMORY.md` under `~/.claude/projects/…`) | Personal, machine, or session-adjacent; **not** the team SoT |
| **Docs** | ADRs, runbooks, Codex/domain, CONTRIBUTING | Human + agent durable product corpus |

**L3-shared layout** (authored by `/workflow:setup` + `/workflow:compound`; stewarded by `/workflow:maintain`):

```text
.agent-tools/memory/
  MEMORY.md                 # Entries index (full); Solutions = pointer only
  state.yml                 # Maintain cadence + last-run summary
  entries/<slug>.md         # type: pattern | gotcha | lesson | process
  solutions/<category>/<slug>.md
```

**Non-goals for L3-shared:** restating ADRs or CONTRIBUTING; personify voice; planning scratch; secrets; product docs under `docs/`. Debugging post-mortems live under `.agent-tools/memory/solutions/`, **not** `docs/solutions/`.

**Loading:** `AGENTS.md` carries a marker-bounded pointer to `MEMORY.md` (installed by `/workflow:setup`). Agents read the index on demand (compound, unfamiliar seams, debugging); they do **not** `@`-import every satellite every turn.

**Harness auto-memory must not be redirected into the repo** (e.g. Claude `autoMemoryDirectory` is restricted for security). Shared strata is written by compound capture/maintain (with user approval on promote/migrate), not by platform auto-writers.

<!-- agent:include claude -->

### Claude Code Implementation

Claude Code maintains two independent memory systems:

- **User-authored**: `CLAUDE.md` files (with scopes: managed policy, project, user, local).
- **Auto-memory**: `MEMORY.md` + topic files written by Claude (subject to 200-line / 25 KB truncation) — this is **L3-local**, not L3-shared.

Team-shared technical memory for agent-tools projects is **`.agent-tools/memory/`**. Prefer writing project-wide captures there via `/workflow:compound`; steward quality via `/workflow:maintain`; keep Claude auto-memory for personal/machine notes or thin pointers.

See the detailed scopes table and primitive list below for Claude’s current mechanisms.

<!-- /agent:include claude -->

<!-- agent:include grok -->

### Grok Implementation

Grok’s approach to persistent memory combines platform features with file-based project context:

- **Persistent User Memory**: Built-in Memory system (toggle + Custom Instructions) that remembers user preferences, style, projects, and recurring facts across conversations on the Grok platform.
- **Project Context**: Strong support for `AGENTS.md` (with good Claude compatibility). Grok Build automatically loads these files for long-term project memory, decisions, and conventions.
- **Skills**: Reusable, modular instruction sets that can act as portable context or rule bundles.
- **Large Context Windows**: Up to 1M–2M tokens in advanced tiers, which reduces reliance on heavy external memory for many workflows.
- **Multi-agent persistence**: Sub-agents can maintain encrypted state across turns.

Grok currently relies primarily on `AGENTS.md`, large context windows, and its built-in Memory feature for persistent context. It has fewer dedicated file-based memory primitives than some other platforms. Most durable project memory lives in `AGENTS.md` and Skills.

<!-- /agent:include grok -->

<!-- agent:include factory -->

### Factory Droid Implementation

Factory Droid has no built-in cross-session memory. All persistent context must be provided through files. The recommended system has three main layers:

- **Project Memory** — `.factory/memories.md` (lives in the repo root and travels with the code)
- **Personal Memory** — `~/.factory/memories.md` (follows the individual across all projects)
- **Rules & Conventions** — `.factory/rules/*.md` (project) and `~/.factory/rules/` (personal)

`AGENTS.md` (both project-level and personal) serves as the central orchestrator that explicitly tells Droid to consult the memory and rules files before acting.

Factory strongly distinguishes between **Memory** (descriptive records of decisions and context) and **Rules** (prescriptive standards for how work should be done).

<!-- /agent:include factory -->

<!-- agent:include personify -->

### Personify Profile (cross-cutting, from agent-tools skills)

The `personify` skill provides a specialized, narrow-scope durable profile for **agent personality, voice, and interpersonal communication facts only**. **Authority for paths, merge cascade, and size limits:** `@personify` (`src/personify/SKILL.md`). Do not invent alternate caps here.

- **Two-layer storage** (user base + project override):
  | Layer | Path | Role |
  |-------|------|------|
  | User | `~/.agent-tools/personify.md` | Cross-project defaults |
  | Project | `.agent-tools/personify.md` | Project/audience delta; wins on conflict |
- Loading: project `AGENTS.md` must import each existing layer (managed `agent-tools:personify-link` block). Typical combined form:
  ```markdown
  @~/.agent-tools/personify.md
  @.agent-tools/personify.md
  ```
- Scope (strict): Only personality traits & behaviors, speaking/writing voice guidance, and persistent interpersonal facts. **No technical decisions, code patterns, architecture, or project history.**
- Size limits (per `@personify`): **per layer** warn / strong / hard **400 / 500 / 600**; **combined** **900 / 1050 / 1200**. Legacy single-file projects without user-space may use a per-file 1,200 cap until promoted.
- On every `/personify` run after init: displays the full current content + live token usage, proposes specific cleanups/consolidations (merges, prunes, rephrasings), and guides the user through the process collaboratively (agent suggests; user directs priorities and approvals). Promote shared rules via `/personify promote`.
- Distinction from other memory: This is **not** general project memory or rules (use charter/AGENTS.md, `.agent-tools/memory/`, etc.). It is narrowly for how the *agent* should present itself and communicate with humans.

<!-- /agent:include personify -->

### Project shared memory (cross-cutting, from agent-tools)

Installed by `/workflow:setup`; capture via `/workflow:compound`; steward via `/workflow:maintain`:

- **Location:** `.agent-tools/memory/` (see levels table above)
- **AGENTS link:** marker block `agent-tools:memory-link begin/end` pointing at `MEMORY.md`
- **Capture routing:** deterministic gate in `/workflow:compound` (solutions → `solutions/`; project-wide patterns/gotchas → `entries/`; decisions → ADRs; voice → personify)
- **Maintain:** `/workflow:maintain` audits L1–L3 (+ run yield), proposes promote/retire, optional `--migrate-solutions` for legacy `docs/solutions/` (compat: `/workflow:compound --maintain`)
- **Cadence:** `state.yml` `interval_days` (default 7) — see @workflow `maintain/references/cadence.md`; soft-prompted from status/continue/capture; `:maintain` always on-demand

---

## Concrete Primitives

<!-- agent:include claude -->

### Claude Code Primitives

The table below lists the specific mechanisms Claude Code currently exposes.

| Primitive                              | Type     | Use when                                                                                                           |
|----------------------------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `<repo>/CLAUDE.md`                     | File     | Team-shared instructions. Default for project-level rules.                                                         |
| `<repo>/CLAUDE.local.md`               | File     | Personal project preferences. Auto-gitignored by `/init`.                                                          |
| `~/.claude/CLAUDE.md`                  | File     | User-wide rules across every project on this machine.                                                              |
| `@~/.claude/<file>` import             | Syntax   | Re-share personal content into a project's CLAUDE.md without committing it. Up to 5-hop chains.                    |
| `.claude/rules/*.md` + `paths:`        | File pattern | Path-scoped instructions loaded only when matching files are touched. The right primitive for "rules that only apply to part of the codebase" — see Pattern 1 below. |
| `~/.claude/rules/*.md`                 | File pattern | User-level rules (path-scoped). Same mechanism, user scope.                                                      |
| `MEMORY.md` + `memory/*.md`            | File set | Auto-memory: Claude writes, you can edit/delete. Index is hard-truncated at 200 lines / 25 KB.                     |
| `claudeMdExcludes` setting             | Glob list | Exclude monorepo CLAUDE.md files at any layer.                                                                    |
| `autoMemoryEnabled` setting (bool)     | Setting  | Per-user, per-project, or local off-switch for auto-memory. Defaults true.                                         |
| `autoMemoryDirectory` setting          | Path     | Override where auto-memory lives. Restricted to policy + user layers (security: prevents cloned repos from redirecting writes). |
| `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`    | Env var  | Hard-disable auto-memory for one session.                                                                          |
| `/memory` slash command                | Command  | Browse/edit memory files; toggle auto-memory; view auto-memory entries.                                            |
| `/clear` (`/reset`, `/new`)            | Command  | Start a new conversation with empty context. Use at task boundaries.                                               |
| `/compact [instructions]`              | Command  | Summarize the conversation so far to free context, optionally with guiding instructions.                           |
| `/dream` (partially shipped)           | Command  | Anthropic's auto-memory consolidation: orient → gather signal → consolidate → prune+index. Surfaced in `/memory` UI as "Auto-dream: on" but may return "Unknown skill: dream" depending on rollout. Manually triggerable via natural-language: "dream", "consolidate my memory files". |
| `claude project purge` (built-in, v2.1.126+) | Command | Nuclear archival: deletes transcripts, task history, file history, project config under `~/.claude/projects/<hash>/`. Use for project handoff or when winding down a stale workspace.   |
| `InstructionsLoaded` hook              | Hook     | Fires when CLAUDE.md or `.claude/rules/*.md` loads. Matchers: `session_start`, `nested_traversal`, `path_glob_match`, `include`, `compact`. Wire-point for size warnings or audit logging. |
| `PreCompact` / `PostCompact` hooks     | Hook     | Wrap conversation compaction events. Useful for deciding when to trigger maintenance.                              |
| `/workflow:maintain`                   | Command (this repo) | Stewardship: run yield + three-tier memory audit (promote/retire; optional `--migrate-solutions`). Compat: `/workflow:compound --maintain`. |
| `.agent-tools/memory/`                 | File set (this repo) | **L3-shared**: committed project memory (`MEMORY.md` + `entries/` + `solutions/`). Preferred home for project-wide captures. |

<!-- /agent:include claude -->

<!-- agent:include grok -->

### Grok Primitives

Grok’s main persistent context mechanisms (as of 2026):

| Primitive                              | Type             | Use when                                                                 |
|----------------------------------------|------------------|--------------------------------------------------------------------------|
| `AGENTS.md` (project root or `~/.grok/`) | File / Orchestrator | Project conventions, build commands, architecture decisions, memory references |
| Custom Instructions + Memory toggle    | Platform feature | User-level persistent preferences and facts across chats                 |
| Skills                                 | Modular instruction sets | Reusable workflows, context bundles, or rule sets                        |
| Large context window (1M–2M tokens)    | Model capability | Reducing need for external memory in complex sessions                    |
| Stateful Responses API                 | API feature      | Server-side conversation memory tied to response IDs                     |
| Multi-agent encrypted state            | System feature   | Persisted sub-agent context across turns                                 |

Grok currently relies primarily on `AGENTS.md`, large context windows, and its built-in Memory feature for persistent context. It has fewer dedicated file-based memory primitives compared with some other platforms.

<!-- /agent:include grok -->

<!-- agent:include factory -->

### Factory Droid Primitives

Factory’s memory system is deliberately file-based and human-maintained. The main primitives are:

| Primitive                              | Type             | Use when                                                                 |
|----------------------------------------|------------------|--------------------------------------------------------------------------|
| `.factory/memories.md`                 | Project memory   | Architecture decisions, domain knowledge, technical debt, project history |
| `~/.factory/memories.md`               | Personal memory  | Individual preferences, style, tooling choices, communication patterns    |
| `.factory/rules/*.md`                  | Project rules    | Prescriptive standards (TypeScript, testing, security, etc.)              |
| `~/.factory/rules/`                    | Personal rules   | Cross-project personal conventions                                        |
| `AGENTS.md` (project + personal)       | Orchestrator     | Central file that tells Droid to consult memories and rules               |
| Memory capture hooks                   | Automation       | Automatically save entries triggered by `#`, `##`, or “remember this”     |
| Memory skills or `/remember` commands  | Interactive      | Help Droid capture, categorize, and format new memories                   |

Factory makes a clear distinction between **Memory** (what was decided + reasoning) and **Rules** (how things must be done going forward).

<!-- /agent:include factory -->

---

## Patterns: Prefer the Primitive

These patterns are intended to be useful regardless of which agent you use.

### Pattern 1 — Externalize Categories of Guidance

**Smell**: A single memory file is becoming bloated because many unrelated rules have accumulated.

**Reach for**: Any path-scoped or category-based primitive the agent supports so that rules only load when relevant.

<!-- agent:include claude -->

**Claude example**: Use `.claude/rules/<category>.md` with a `paths:` frontmatter matcher instead of putting everything in `CLAUDE.md`.

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Grok example**: Use `AGENTS.md` (or a dedicated skills file) to externalize rules so they are loaded only when relevant, combined with Grok’s large context window and Skills feature for modular context.

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Factory example**: Store category-specific guidance in `.factory/rules/<category>.md` (or the appropriate layer) and reference the file from `AGENTS.md`. Droid will then automatically load the rules when working in the relevant context.

<!-- /agent:include factory -->

### Pattern 2 — Personal vs Shared Rules

**Smell**: You want personal preferences to follow you across projects without polluting the team repo.

**Reach for**: A local-only or user-scoped primitive.

<!-- agent:include claude -->

**Claude example**: `CLAUDE.local.md` (gitignored) for project-specific personal rules, or `~/.claude/<file>.md` + `@` import for cross-project personal rules.

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Grok example**: Use `AGENTS.md` (or a dedicated skills file) to externalize rules so they are loaded only when relevant, combined with Grok’s large context window and Skills feature for modular context.

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Factory example**: Store personal preferences and style in `~/.factory/memories.md` and reference the file from `~/.factory/AGENTS.md`. This keeps personal conventions available in every project without polluting any repo.

<!-- /agent:include factory -->

### Pattern 3 — Convert Prose to Enforcement

**Smell**: Important rules are frequently missed even though they are written in memory.

**Reach for**: Any hook, required artifact, or tooling primitive that can enforce the behavior instead of documenting it.

<!-- agent:include claude -->

**Claude example**: Use hooks (`PostToolUse`, `InstructionsLoaded`, etc.) or pre-commit hooks rather than writing “always run the linter.”

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Grok example**: Use `AGENTS.md` (or a dedicated skills file) to externalize rules so they are loaded only when relevant, combined with Grok’s large context window and Skills feature for modular context.

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Factory example**: Use PostToolUse hooks or custom skills to automatically enforce rules (e.g., linting, formatting, security checks) rather than relying only on documentation in prose.

<!-- /agent:include factory -->

### Pattern 4 — Prune Transient Context

**Smell**: Old, one-off context (e.g., debugging details from a specific task) lingers and creates noise.

**Reach for**: Any deletion, archiving, or compaction primitive the agent supports.

<!-- agent:include claude -->

**Claude example**: Use `/memory` to review and delete entries, or `/workflow:maintain --focus staleness`.

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Grok example**: Use the Memory viewer to review and delete individual memories. Leverage compaction features when available.

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Factory example**: Periodically review and prune `memories.md` entries. Archive old decisions using `<details>` blocks.

<!-- /agent:include factory -->

### Pattern 5 — Archive on Project End or Handoff

**Smell**: A project is winding down or being handed off, and you want to preserve useful history without loading it every session.

**Reach for**: Archival or purge primitives.

<!-- agent:include claude -->

**Claude example**: Use `claude project purge` for full handoff, or manually move topic files into an archive folder and remove their references from `MEMORY.md`.

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Grok example**: Use the Memory management tools to archive or delete project-related memories. Consider exporting key decisions before closing the project.

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Factory example**: Archive or move old entries in `.factory/memories.md`. Use `<details>` blocks for historical decisions that no longer need to load by default.

<!-- /agent:include factory -->

---

## Hygiene Practices

**General principle**: Treat memory like code. Review it when things go wrong, prune regularly, and prefer enforcement over documentation.

<!-- agent:include claude -->

### Claude-Specific Hygiene

- Per-line audit (“Would removing this cause mistakes?”)
- Convert prose to hooks where possible
- Check `CLAUDE.md` into git
- Periodic contradiction checks across all layers

(For sources and known limitations, see the Sources section inside the Claude block below.)

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Grok example**: Use the Memory toggle + periodic review of Custom Instructions and `AGENTS.md`. Leverage large context and Skills for hygiene. Review memories for accuracy and prune when context pressure appears.

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Factory example**: Follow the Power User checklist. Conduct quarterly reviews of `memories.md` and rules files. Prune or archive old entries (using `<details>` blocks for historical decisions). Combine with Droid Shield and automation hooks for ongoing enforcement. Teams are encouraged to maintain project-level memory and rules.

<!-- /agent:include factory -->

---

## When to Audit Memory

Use a deliberate memory maintenance workflow when:

- Memory files or context are approaching practical limits (bloat, truncation, or degraded agent performance) — including either personify layer approaching its 400-token warn (or combined near 900), shared `MEMORY.md` Entries section past ~120 lines, or Claude local MEMORY.md near 200 lines / 25 KB
- Maintain due per `.agent-tools/memory/state.yml` (`interval_days`, default 7) — soft-prompted from status/continue/capture; run `/workflow:maintain` anytime on demand
- New contributors or team members are onboarding
- The project has undergone significant changes that may have invalidated previous decisions or context
- Before sharing memory/rules with a wider team or repository
- Harness-local auto-memory has grown project-wide guidance that should be promoted to `.agent-tools/memory/entries/`
- Legacy `docs/solutions/` still exists and should be migrated (`/workflow:maintain --migrate-solutions`)
- Run yield is stale or ≥5 closed runs since last yield glance

The specific triggers and tools vary by agent platform. Primary tool: **`/workflow:maintain`**.

<!-- agent:include claude -->

For Claude Code, common triggers include `MEMORY.md` approaching the 200-line / 25 KB cutoff, or noticing the agent ignoring instructions that previously worked reliably.

<!-- /agent:include claude -->

<!-- agent:include grok -->

For Grok, common triggers include Custom Instructions or `AGENTS.md` growing large, before major refactors, or when the agent begins ignoring previously established patterns. Use the built-in Memory viewer plus periodic review of project files.

<!-- /agent:include grok -->

<!-- agent:include factory -->

For Factory Droid, common triggers include `memories.md` files growing large, before onboarding new team members, after major refactors, or before sharing the project with others. Use skills or hooks for maintenance.

<!-- /agent:include factory -->

<!-- agent:include personify -->

For the personify profile, common triggers include approaching the per-layer 400-token warn (or combined 900), the agent drifting in voice/tone/consistency, or low-signal facts accumulating. Use `/personify` — it will display the current full memory + token usage and guide proactive cleanup/maintenance.

<!-- /agent:include personify -->

---

## Sources & Further Reading

<!-- agent:include claude -->

**Primary (Anthropic)**:
- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/best-practices
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/settings

Known limitations and feature requests are tracked in the Anthropic Claude Code repository.

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Primary (xAI / Grok)**:
- Grok Build documentation and release notes (memory, Skills, AGENTS.md support)
- https://x.ai (for latest on Grok Build, Memory features, and context capabilities)
- AGENTS.md is treated as the primary long-term project context mechanism (with strong Claude compatibility)

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Primary (Factory.ai)**:
- https://docs.factory.ai/guides/power-user/memory-management
- https://docs.factory.ai/guides/power-user/rules-conventions
- https://docs.factory.ai/guides/power-user/setup-checklist

<!-- /agent:include factory -->
