# Codex – Skill Authoring Quick Reference

**Last Updated**: 2026-06-01  
**Sources**:
- Primary: https://developers.openai.com/codex/skills
- Related: https://developers.openai.com/codex/guides/agents-md
- Standard: https://agentskills.io

---

## Overview

OpenAI Codex uses the open **Agent Skills** standard (SKILL.md + YAML frontmatter + optional supporting files). Skills are the primary mechanism for extending Codex with reusable, task-specific expertise. Codex performs **progressive disclosure**: it receives only the `name` + `description` (plus path) for every skill up front (capped ~2% of context), then loads the full `SKILL.md` body only when it selects the skill for a task.

Skills work in the Codex app, CLI, and IDE extension.

---

## Core Concepts & Differences

- A skill is a directory containing at minimum `SKILL.md` (required: `name` + `description` in frontmatter) plus optional `scripts/`, `references/`, `assets/`, and `agents/openai.yaml`.
- Discovery walks from CWD upward to repo root for project skills, plus user and system locations.
- **AGENTS.md** is the canonical portable memory file (global `~/.codex/AGENTS.md` + per-project at repo root; precedence rules; `AGENTS.override.md` for temp global overrides). Codex reads AGENTS.md before doing work.
- Strong native support for **MCP** (Model Context Protocol) tools and **subagents**.
- Native worktree support in the app UI (separate threads/environments); git worktrees used by external orchestration (e.g. this corpus) are respected.
- Configurable via `~/.codex/config.toml` (enable/disable specific skills, etc.).
- Optional `agents/openai.yaml` inside a skill for UI metadata (display name, icon, brand color), invocation policy, and declared tool dependencies.

---

## Tooling & Capabilities

- Full tool-calling + computer use.
- MCP servers for external capabilities.
- Subagent dispatch for isolated or parallel execution.
- Shell access and sandboxed environments.
- Built-in skill creator (`$skill-creator`) and installer (`$skill-installer`).
- Automatic detection of skill changes (restart Codex if a new skill does not appear).

**Notable strengths**:
- Excellent large-context + reasoning for complex orchestration.
- First-class AGENTS.md + Skills combination for memory + procedures.
- Plugin distribution model for sharing skills beyond a single machine/repo.

---

## Environment & Context Assumptions

**Our support choice (pragmatic)**: This corpus installs Codex skills to `~/.codex/skills/` and `./.codex/skills/` (1:1 with the "codex" agent token). Official current docs primarily document `~/.agents/skills/` (user) and `.agents/skills/` (repo, multi-level). Codex may still discover skills in `~/.codex/skills/` via legacy paths or config; users following official docs can symlink or adjust `config.toml` as needed.

- Project skills (official): `.agents/skills/<name>/` (scanned from CWD up through repo root).
- User skills (official primary): `~/.agents/skills/<name>/`.
- Codex home (AGENTS.md, config, memories): `~/.codex/` (or `$CODEX_HOME`).
- Global AGENTS.md: `~/.codex/AGENTS.md` (or override).
- Project AGENTS.md: repo root (loaded with precedence).
- Skills support symlinks (both for skill dirs and inside them).
- `~/.codex/config.toml` controls per-skill enablement and other behavior.

---

## Invocation & Input Handling

- **Explicit**: In CLI/IDE use `/skills` or type `$<skill-name>` to mention/invoke.
- **Implicit**: Codex matches task against the initial name+description list and loads the full body automatically when relevant.
- Frontmatter controls relevance (`description` is the primary signal — keep it concise, front-load use cases and trigger words).
- Supports `$ARGUMENTS` and structured parsing.
- `user-invocable` / `disable-model-invocation` semantics from the standard are respected where implemented.

---

## Common Portability Issues

- Directory conventions differ: prefer `.agents/skills/` in docs/examples for Codex users, but this corpus uses `.codex/skills/` for installation symmetry with `~/.codex/`.
- Worktree sidecar state (e.g. `.codex/worktrees/<name>/`) may differ from Claude's `.claude/worktrees/`; git worktrees themselves are portable.
- Memory split: AGENTS.md (explicit, portable, human-authored) + separate `~/.codex/memories/` (auto-generated summaries, rollouts, etc.). Do not assume Claude-style `MEMORY.md` + hooks.
- Some Claude-specific frontmatter (e.g. `context: fork`) or dynamic injection (`!command`) may need markup or generalization.
- Config and enablement live in `~/.codex/config.toml` rather than settings JSON.

---

## Emerging / Notable Features

- Tight integration with Responses API, computer use, and voice agents.
- Plugin packaging for skills + MCP + presentation assets.
- Growing emphasis on guardrails, approvals, and enterprise controls.
- Worktree + multi-thread UX in the desktop app for parallel agent work.

---

## Notes & Gotchas

- After adding or editing skills (or changing `config.toml`), restart Codex for reliable discovery.
- Write tight `description` frontmatter — it is what Codex sees in the initial (budgeted) list.
- AGENTS.md is your primary lever for project conventions; load it early and keep it sparse + high-signal.
- Use the optional `agents/openai.yaml` only when you need UI polish or declared MCP deps in the Codex app.
- The standard is intentionally portable — skills authored here with judicious markup should transfer cleanly to Codex (and vice-versa via `skills:import`).

---

*This document is maintained by `skills:import` via periodic refresh and is intended as a quick reference for skill authors and the import/evolve processes.*