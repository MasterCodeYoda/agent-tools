# Claude – Skill Authoring Quick Reference

**Last Updated**: 2026-05-17  
**Sources**:
- Primary: https://docs.anthropic.com/en/docs/claude-code/skills
- Related: https://docs.anthropic.com/en/docs/claude-code/overview

---

## Overview

Claude Code (Anthropic’s coding agent) uses **skills** as the primary way to extend its capabilities with reusable, structured instructions. Skills are defined in `SKILL.md` files and are loaded on-demand based on relevance rather than being present in every context.

Skills replace repeatedly pasting the same instructions and help keep long procedural content out of `CLAUDE.md`. They follow the open **Agent Skills** standard with Claude-specific extensions.

---

## Core Concepts & Differences

- Skills are **discovered and loaded automatically** when relevant (based on the `description` in frontmatter).
- Content is injected into context only when the skill is used, which helps control token usage.
- Supports **dynamic context injection** using `!command` syntax (e.g. `!git diff HEAD`).
- Strong support for **subagents** (`context: fork`).
- Skills can be personal (`~/.claude/skills/`) or project-scoped (`.claude/skills/`), with enterprise-managed overrides taking highest priority.
- Skills are the recommended way to handle complex, repeatable workflows instead of bloating memory files.

---

## Tooling & Capabilities

- Full access to the model’s tool use capabilities when the skill is active.
- Supports `allowed-tools` restriction in frontmatter.
- Can use shell commands via dynamic injection (`!` prefix).
- Supports hooks and custom tool definitions in advanced setups.
- Can invoke subagents for isolated execution.

**Notable limitations**:
- Skills are still subject to the model’s context window.
- Very large skills can still be expensive if loaded frequently.

---

## Environment & Context Assumptions

- Personal skills live in `~/.claude/skills/<skill-name>/SKILL.md`
- Project skills live in `.claude/skills/<skill-name>/SKILL.md` (discovered in current and parent directories)
- Enterprise-managed skills take precedence.
- Skills support live reloading in most environments.
- Can reference supporting files (templates, examples, scripts) stored alongside `SKILL.md`.

---

## Invocation & Input Handling

- Can be invoked automatically when the model decides it is relevant (based on `description`).
- Can be invoked manually with `/skill-name`.
- Supports `$ARGUMENTS` and structured argument parsing.
- Frontmatter controls:
  - `description` — used for relevance matching
  - `disable-model-invocation: true` — forces manual invocation only
  - `user-invocable` — controls whether users can call it directly
  - `context: fork` — runs the skill in a subagent

---

## Common Portability Issues

- Heavy reliance on Claude-specific dynamic injection (`!command`) can break portability.
- Use of Claude-specific frontmatter fields (`context: fork`, `disable-model-invocation`, etc.) may not be supported elsewhere.
- Directory conventions (`.claude/`) differ from other agents.
- Worktree behavior and exit prompts are Claude-specific.
- Memory handling and `CLAUDE.md` vs skill separation is more mature in Claude than in most other agents.

---

## Emerging / Notable Features

- Growing support for **subagents** and isolated execution contexts.
- Integration with **Model Context Protocol (MCP)** for external tools.
- Increasing use of skills for complex multi-step workflows and agent orchestration.
- Enterprise features for centrally managed skill libraries.

---

## Notes & Gotchas

- Keep skill content concise — loaded skill text counts toward context.
- Use `description` thoughtfully; it is the main signal for automatic loading.
- Prefer skills over `CLAUDE.md` for anything long or conditionally useful.
- Skills can (and often should) include supporting files referenced from `SKILL.md`.

---

*This document is maintained by `skills:import` via periodic refresh and is intended as a quick reference for skill authors and the import process.*