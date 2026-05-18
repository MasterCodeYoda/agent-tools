# Factory (Droid) – Skill Authoring Quick Reference

**Last Updated**: 2026-05-17  
**Sources**:
- Primary: https://docs.factory.ai/cli/configuration/skills
- Related guides: https://docs.factory.ai/guides/skills/*

---

## Overview

Factory.ai’s **Droid** uses a mature `SKILL.md`-based system (very similar to Claude Code). Skills are the primary way to package reusable workflows, team conventions, guardrails, checklists, and supporting files. They support both automatic relevance-based loading and explicit invocation via `/skill-name`.

Custom commands have been largely merged into the skills system.

---

## Core Concepts & Differences

- Skills live in directories containing a `SKILL.md` (or `skill.mdx`) with YAML frontmatter + Markdown instructions.
- Strong support for **supporting files** (scripts, templates, checklists, schemas) that can be called from the skill.
- Excellent for enterprise/team standardization.
- Skills can be workspace-level (`.factory/skills/`) or personal (`~/.factory/skills/`).
- Emphasis on **verification steps** and required artifacts in skill definitions.

---

## Tooling & Capabilities

- Can bundle and call custom scripts (Node, Python, shell, etc.).
- Good integration with MCP for external tools.
- Supports subagents / custom Droids.
- Strong hook system.

**Notable strengths**:
- Very good at encoding team process and safety guardrails.
- Cookbook of high-quality, opinionated skill templates available.

---

## Environment & Context Assumptions

- Workspace skills: `<repo>/.factory/skills/<skill-name>/SKILL.md`
- Personal skills: `~/.factory/skills/<skill-name>/SKILL.md`
- Also reads from `.agent/skills/` for compatibility.
- Monorepo-friendly with root or per-package skill folders.
- Restart of Droid/CLI is often required after adding new skills.

---

## Invocation & Input Handling

- Can be auto-invoked by the Droid when relevant (based on `description`).
- Can be manually invoked with `/skill-name`.
- Strong frontmatter controls:
  - `name`
  - `description` (critical for auto-loading)
  - `user-invocable`
  - `disable-model-invocation`
- Good support for structured arguments and `$ARGUMENTS`.

---

## Common Portability Issues

- Heavy use of bundled scripts and relative paths can be Factory-specific.
- Strong emphasis on “verification” and required artifacts is more pronounced than in most other agents.
- `.factory/` directory convention differs from Claude (`.claude/`) and Grok (`.grok/`).
- Some advanced script bundling patterns may not translate cleanly.

---

## Emerging / Notable Features

- Growing library of high-quality skill templates (frontend, product, data, browser automation, etc.).
- Increasing integration with custom Droids and subagents.
- Strong enterprise focus on centrally managed skill libraries.

---

## Notes & Gotchas

- Keep skills narrow and single-responsibility when possible.
- Include explicit verification steps and required artifacts.
- Supporting files (scripts, templates) are a first-class part of the system — don’t treat a skill as only the `SKILL.md`.
- Restart Droid after adding or modifying skills in most environments.

---

*This document is maintained by `skills:import` via periodic refresh.*