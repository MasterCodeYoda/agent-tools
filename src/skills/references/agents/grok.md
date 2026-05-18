# Grok – Skill Authoring Quick Reference

**Last Updated**: 2026-05-17  
**Sources**:
- Primary: https://docs.x.ai/build/features/skills-plugins-marketplaces
- Related: https://docs.x.ai/build/overview

---

## Overview

Grok Build (xAI) uses a flexible **skills** system where skills are folders containing markdown instructions, scripts, and supporting resources. Skills are automatically discovered and can be invoked as slash commands. The system is deliberately designed with strong **Claude Code compatibility**, allowing many existing Claude skills to work with minimal or no changes.

---

## Core Concepts & Differences

- Skills are discovered from `./.grok/skills/`, `~/.grok/skills/`, enabled plugins, and configured paths.
- Skills appear as native slash commands in the TUI.
- Strong emphasis on **plugins** as a way to bundle and distribute skills + hooks + MCP servers.
- First-class support for **subagents** and parallel execution.
- `grok inspect` is the key diagnostic command to see all discovered skills, hooks, and plugins.
- Excellent backward compatibility with Claude’s skill, plugin, and memory formats (`.claude/skills/`, `CLAUDE.md`, `AGENTS.md`, etc.).

---

## Tooling & Capabilities

- Full tool-calling support with strong reasoning.
- Supports custom scripts and external tools via MCP (Model Context Protocol).
- Hooks system for lifecycle events (before/after tool calls, session start/end, etc.).
- Good support for parallel subagent execution.

**Notable strengths**:
- Very strong at multi-agent research and parallel workflows.
- `grok inspect` gives excellent visibility into the current environment.

---

## Environment & Context Assumptions

- Project-level skills: `./.grok/skills/<skill-name>/`
- User-level skills: `~/.grok/skills/<skill-name>/`
- Plugins can contribute additional skills from their directories.
- Skills can be organized in monorepos with discovery walking up to the repo root.
- Strong support for `AGENTS.md` / `CLAUDE.md` style memory files (Claude compatibility).

---

## Invocation & Input Handling

- Skills can be invoked manually via `/<skill-name>`.
- Automatic relevance-based loading is supported but less emphasized than in Claude.
- Supports `$ARGUMENTS` and structured input.
- Works well with both interactive TUI and headless (`grok -p`) modes.

---

## Common Portability Issues

- Grok is one of the most forgiving targets due to its Claude compatibility layer.
- Some Claude-specific dynamic injection patterns (`!command`) may not work identically.
- Worktree and memory file handling can differ in subtle ways from Claude.
- Plugin/hook system is more prominent than in most other agents.

---

## Emerging / Notable Features

- Growing marketplace for plugins and skills.
- Strong focus on agentic tool use and multi-agent orchestration.
- Good support for custom models and the Agent Client Protocol (ACP).
- `grok inspect` continues to expand as a first-class observability tool.

---

## Notes & Gotchas

- Use `grok inspect` liberally when developing skills — it is the best way to understand what the agent currently sees.
- Because of Claude compatibility, many existing skills “just work,” but test important ones.
- Skills + plugins + hooks form a powerful combined extension system — don’t treat skills in isolation.

---

*This document is maintained by `skills:import` via periodic refresh.*