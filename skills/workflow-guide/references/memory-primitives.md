# Claude Code Memory Primitives

Reference for the file types, settings, hooks, and slash commands that govern what Claude Code remembers across sessions. Used by `/workflow:compound` (especially `--maintain` mode) and consulted when memory feels stale, bloated, or mis-scoped.

The patterns below favor Anthropic's documented primitives over hand-rolled alternatives. When a primitive exists, prefer it: less prose in CLAUDE.md, more behavior enforced by the platform.

## Two Memory Systems, Two Failure Modes

Claude Code has two independent memory systems, both auto-loaded each session.

### `CLAUDE.md` — user-authored

Plain markdown the user maintains. Loaded in full each session, walked up the directory tree, concatenated rather than overridden, supports `@path` imports up to 5 hops.

**Failure mode:** attention dilution. There is no hard cutoff — long files load — but priority gets diluted and instructions start being ignored. Anthropic's docs target **under 200 lines per file** and call out "the over-specified CLAUDE.md" as an explicit anti-pattern.

Scopes (high → low precedence in load order; concatenation, not override):

| Scope          | Path                                                | Shared with                              |
|----------------|-----------------------------------------------------|------------------------------------------|
| Managed policy | `/Library/Application Support/ClaudeCode/CLAUDE.md` (macOS), `/etc/claude-code/CLAUDE.md` (Linux), `C:\Program Files\ClaudeCode\CLAUDE.md` (Windows) | Org policy        |
| Project        | `<repo>/CLAUDE.md` or `<repo>/.claude/CLAUDE.md`    | Team via source control                  |
| User           | `~/.claude/CLAUDE.md`                               | Just you, all projects on this machine   |
| Local          | `<repo>/CLAUDE.local.md` (gitignored)               | Just you, this project                   |

### Auto-memory — Claude-authored

`MEMORY.md` index plus topic files at `~/.claude/projects/<encoded-path>/memory/`. Per-working-tree (machine-local; all worktrees of the same repo share one directory). Requires Claude Code v2.1.59+.

**Failure mode:** silent truncation. The first **200 lines OR 25 KB of `MEMORY.md`, whichever comes first**, are loaded at session start. Content past that threshold is dropped without warning. Truncation drops from the bottom — newest entries first.

Topic files referenced by `MEMORY.md` are loaded on demand based on the index, not on a global threshold.

## The Primitives Table

| Primitive                              | Type     | Use when                                                                                                           |
|----------------------------------------|----------|-------------------------------------------------------------------------------------------------------------------|
| `<repo>/CLAUDE.md`                     | File     | Team-shared instructions. Default for project-level rules.                                                         |
| `<repo>/CLAUDE.local.md`               | File     | Personal project preferences. Auto-gitignored by `/init`.                                                          |
| `~/.claude/CLAUDE.md`                  | File     | User-wide rules across every project on this machine.                                                              |
| `@~/.claude/<file>` import             | Syntax   | Re-share personal content into a project's CLAUDE.md without committing it. Up to 5-hop chains.                    |
| `.claude/rules/*.md` + `paths:` frontmatter | File pattern | Path-scoped instructions loaded only when matching files are touched. The right primitive for "rules that only apply to part of the codebase" — see Pattern 1 below. |
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
| `/workflow:compound --maintain`        | Command (this repo) | The deliberate, evidence-producing alternative to `/dream` — a three-tier audit across all memory levels with selective approval. See "When to run compound --maintain" below. |

Note: there is no `PreMemoryWrite` / `PostMemoryWrite` hook. That's an open feature request (anthropics/claude-code#44820). Capture-time gating must rely on the auto-memory rules in the user prompt, not on hook enforcement.

## Patterns: Use the Primitive Instead

Patterns observed in community advice that map to existing primitives — when you spot one, prefer the primitive.

### Pattern 1 — Externalize a category of guidance from CLAUDE.md

**Smell:** CLAUDE.md is over 200 lines because a category of rules has accreted (e.g., "always check the failure log for migrations", "for security-sensitive code, do X").

**Reach for:** `.claude/rules/<category>.md` with `paths:` frontmatter. The rule loads only when matching files are touched, keeping CLAUDE.md lean while preserving the guidance.

```markdown
---
paths:
  - "src/migrations/**"
  - "*.sql"
---
# Migration Rules
- Run `pnpm db:dry-run` before applying
- Never reorder columns in production schemas
```

This is the primitive Hiroyuki's "categorized failure logs in 5 separate files" pattern was reinventing. With `paths:`, the routing is automatic — no "check the failure log before this task" preamble needed.

### Pattern 2 — Personal rules in a shared repo

**Smell:** "I want my CLAUDE.md preferences across all my project copies but I can't commit them to the team repo."

**Reach for:** `CLAUDE.local.md` (auto-gitignored) for project-specific personal preferences. For cross-project personal rules, write them once at `~/.claude/<file>.md` and `@~/.claude/<file>.md` from your project CLAUDE.md.

### Pattern 3 — Behavior enforced by tooling, not by prose

**Smell:** CLAUDE.md says "always run the linter before committing" — and the user reads it, the agent reads it, but it's still missed sometimes.

**Reach for:** a hook (e.g., `PostToolUse` matching write/edit operations) or a pre-commit hook in the repo. Anthropic best-practices: *"If a tool can enforce it, don't write prose about it. Convert prose to hooks where possible."*

### Pattern 4 — One-time context, not durable rule

**Smell:** Auto-memory captured something that was relevant to one task — e.g., "user is debugging the OAuth flow today". Now it's permanent noise.

**Reach for:** `/memory` to view and delete the entry, or `/workflow:compound --maintain --focus staleness` to surface and prune the class systematically. Don't wait for the 200-line cutoff to silently drop it.

### Pattern 5 — Project ending, content worth retaining

**Smell:** A long-running project is winding down. You want to keep memory accessible but stop loading it on every session.

**Reach for:** `claude project purge` for full handoff (deletes everything under `~/.claude/projects/<hash>/`). For partial archival, manually move topic files out of `memory/` into a sibling `memory-archive/` and remove their references from `MEMORY.md` — they remain on disk and grep-able, but no longer load.

## Anthropic-Endorsed Hygiene Practices

From https://code.claude.com/docs/en/best-practices and https://code.claude.com/docs/en/memory:

- **Per-line audit.** "For each line, ask: 'Would removing this cause Claude to make mistakes?' If not, cut it."
- **Treat memory like code.** Review when things go wrong, prune regularly, test changes by observing whether behavior actually shifts.
- **Convert prose to enforcement.** "If Claude already does something correctly without the instruction, delete it or convert it to a hook."
- **Bloat is a behavior bug.** "Bloated CLAUDE.md files cause Claude to ignore your actual instructions."
- **Check CLAUDE.md into git.** "The file compounds in value over time" — and git is the recovery layer if pruning goes too far.
- **Periodic contradiction check.** Across CLAUDE.md, nested CLAUDE.md, `.claude/rules/`, and auto-memory.

## When to Run `/workflow:compound --maintain`

Compound's maintain mode is the deliberate alternative to `/dream`'s autonomous consolidation. Use it when:

- `MEMORY.md` index is approaching the 200-line / 25 KB cutoff (run with `--level memory`)
- A new contributor reads `CLAUDE.md` and finds rules that contradict actual code (run with `--focus accuracy`)
- After significant codebase changes that may have invalidated memory (run with `--focus staleness`)
- Periodic hygiene — quarterly or after major project milestones (run unscoped for full hierarchy)
- Before wider sharing of `<repo>/CLAUDE.md` with the team

Compound and `/dream` are complementary, not competing: `/dream` is autonomous and runs between sessions; `compound --maintain` is user-invoked and produces a Quality Report with selective approval. When `/dream` is unavailable in your install (it's still rolling out), `compound --maintain --level memory` covers the same ground deliberately.

## Sources

Primary (Anthropic):
- https://code.claude.com/docs/en/memory — memory file layout, 200-line cutoff, scopes
- https://code.claude.com/docs/en/best-practices — hygiene guidance, "convert prose to hooks"
- https://code.claude.com/docs/en/commands — slash command reference
- https://code.claude.com/docs/en/hooks — hook event taxonomy
- https://code.claude.com/docs/en/settings — `autoMemoryEnabled`, `claudeMdExcludes`, etc.

Issues tracking known limitations:
- anthropics/claude-code#44820 — `PreMemoryWrite` / `PostMemoryWrite` hooks (open feature request)
- anthropics/claude-code#39135 — `/dream` UI hint vs. "Unknown skill" rollout state
- anthropics/claude-code#40210 — `MEMORY.md` truncates from bottom (newest first)
- anthropics/claude-code#56786 — silent-truncation warning easy to miss
