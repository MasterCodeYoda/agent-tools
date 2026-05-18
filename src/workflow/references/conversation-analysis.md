# Conversation History Analysis

Reference for extracting signals from agent conversation history. Used by `/evolve`, `/workflow:compound`, and `/workflow:audit` for data-driven improvement.

---

## Why Conversation History Analysis Matters

Even with good memory primitives, agents can still lose or under-utilize valuable context across sessions. Analyzing conversation history allows us to surface:

- Command usage patterns and friction points
- Problems that were solved but never documented
- Recurring failure modes that should be turned into durable rules or skills
- Signals that a skill or memory file is stale or incomplete

This analysis is one of the main inputs to `/workflow:compound --maintain` and the broader evolution of the skill corpus.

---

## Data Sources

Different agents expose different kinds of conversation history. The goal is to extract useful signals (frequency, friction, outcomes, undocumented solutions) while respecting privacy and project boundaries.

<!-- agent:include claude -->

### Claude Code Data Sources

Claude Code stores rich, queryable conversation history locally. The four primary sources are:

1. **Command History** (`~/.claude/history.jsonl`)  
   JSONL file with one entry per user input. Useful for command usage frequency and invocation patterns.

2. **Session Quality Facets** (`~/.claude/usage-data/facets/{sessionId}.json`)  
   Post-session analysis containing `underlying_goal`, `outcome`, `friction_counts`, `user_satisfaction`, and `brief_summary`. Excellent for detecting friction and solved-but-undocumented problems.

3. **Conversation Database** (`~/.claude/__store.db`)  
   SQLite database with full message history (`base_messages`, `user_messages`, `assistant_messages`). Enables deep reconstruction of conversations and tool usage.

4. **Project Conversations** (`~/.claude/projects/{encoded-path}/`)  
   Per-project directories containing session transcripts and subagent data.

**Project Scoping Note**: History is stored globally. Always filter by project root (using prefix matching) when doing project-specific analysis.

<!-- /agent:include claude -->

<!-- agent:include grok -->

### Grok Data Sources

Grok stores conversation history primarily at the platform level, with additional context available through project files:

- **Platform Session History & Memory**: Grok maintains persistent user memory (via the Memory feature) and session history accessible through the platform and Grok Build.
- **Grok Build Logs & State**: When using Grok Build (the coding agent), session activity, plans, and tool use are logged locally and in the platform.
- **AGENTS.md + Skills**: These serve as the main durable project context. Custom Skills can be written to automatically capture or summarize important sessions into `AGENTS.md` or dedicated memory files.
- **Large Context**: Advanced tiers offer very large context windows (1M–2M tokens), which can reduce the need for deep historical extraction in many cases.

**Project Scoping**: Most durable context lives in repo-level `AGENTS.md`. Platform memory is user-scoped but can be supplemented with project-specific Skills and files.

<!-- /agent:include grok -->

<!-- agent:include factory -->

### Factory Droid Data Sources

Factory Droid stores conversation and session data primarily through the platform, with some local capabilities:

- **Platform Session History**: The Factory web/app provides rich session replay, audit logs, and conversation history across all interactions with Droid.
- **Audit & Observability Tools**: Built-in audit trails that track decisions, tool use, and outcomes — useful for the "Finding Persistence" and "Recurring Friction" patterns.
- **Local / CLI Logs**: When using Droid in the terminal, session state and logs can be captured locally (location depends on configuration).
- **Custom Skills & Hooks**: Can be used to automatically log or summarize sessions into `.factory/memories.md` or dedicated audit files.

**Project Scoping**: Most platform history is already scoped to repositories or workspaces. Local logs usually live inside the project or user config.

<!-- /agent:include factory -->

---

## Signal Extraction Patterns

The following patterns are generally useful. The specific data sources and tooling vary by agent.

### Command Usage Frequency

Identify which commands are used most often in a project or across projects. This helps surface over-used or under-used skills.

### Session Quality by Command

Correlate commands with session outcomes and friction signals. Useful for identifying which skills or workflows are causing pain.

### Undocumented Solutions

Find sessions that ended successfully (`fully_achieved`) with meaningful summaries but have no corresponding entry in `docs/solutions/`.

### Recurring Friction Patterns

Group friction signals thematically to discover systemic issues that should be turned into rules, skills, or memory updates.

### Finding Persistence (for audits)

Compare current audit findings against previous audit sessions to distinguish new issues from recurring ones.

<!-- agent:include claude -->

**Claude Code Implementation**

All of the patterns above can be executed by querying the four data sources listed in the Data Sources section. See the original extraction examples for concrete queries and code patterns.

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Grok Implementation**

Signal extraction on Grok is typically done through a combination of platform history review, large context reasoning, and custom Skills that summarize or log important sessions. Many teams build lightweight Skills that capture recurring friction or successful patterns directly into `AGENTS.md` or project memory files.

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Factory Implementation**

Most of the patterns above can be performed using Factory’s platform audit tools and session history, combined with custom skills that summarize or query past interactions. For deeper analysis, teams often export session data or use dedicated audit skills that write structured findings into `.factory/memories.md` or a project audit log.

<!-- /agent:include factory -->

---

## Privacy Guidance

When analyzing conversation history, follow these principles regardless of agent:

- **Extract patterns, not content.** Report themes and counts (“3 sessions had friction with architecture guidance”) rather than quoting specific user messages or code.
- **Keep analysis local.** Signals should only feed into local evolve/compound/audit workflows.
- **Aggregate by default.** Prefer counts, categories, and summaries over individual session details.
- **Respect project boundaries.** Default to current-project filtering. Only do cross-project analysis when explicitly requested.
- **Anonymize where possible.** Use `brief_summary` fields or similar when they exist.

<!-- agent:include claude -->

**Claude-specific note**: The `brief_summary` field in quality facets is already designed to be a safe, anonymized summary. Prefer it over raw message content.

<!-- /agent:include claude -->

<!-- agent:include grok -->

**Grok-specific note**: Grok’s Memory feature includes user controls to view, edit, or delete stored memories. When doing analysis, respect user privacy settings and platform data policies. Most durable project context lives in `AGENTS.md`, which is under user control.

<!-- /agent:include grok -->

<!-- agent:include factory -->

**Factory-specific note**: Factory offers strong enterprise controls around data residency, audit logging, and access to conversation history. When doing analysis, respect organizational policies around session data and use the platform’s built-in audit features where available.

<!-- /agent:include factory -->
